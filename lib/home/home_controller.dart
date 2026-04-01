import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String databaseUrl =
    'https://esp32-smart-home-5643e-default-rtdb.firebaseio.com/';

class HomeController extends ChangeNotifier {
  final Map<String, bool> relayStatus = {};
  final Map<String, String> deviceNames = {};

  bool editMode = false;
  bool loading = true;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  late SharedPreferences _prefs;

  // holds which relays are controlled by sensors (e.g. {"relay2","relay4"})
  Set<String> sensorsSet = {};

  // timeout in seconds stored in Firebase at /timeout
  int timeoutSec = 60;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _prefs = await SharedPreferences.getInstance();
    await fetchDevicesFromDatabase();
  }

  void setEditMode(bool value) {
    if (editMode == value) return;
    editMode = value;
    notifyListeners();
  }

  String formatTimeoutLabel(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    if (h > 0) return "${h}h ${m}m ${s}s";
    if (m > 0) return "${m}m ${s}s";
    return "${s}s";
  }

  Future<void> fetchDevicesFromDatabase() async {
    try {
      final url = Uri.parse("$databaseUrl/.json");
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != "null") {
        final data = jsonDecode(response.body);

        relayStatus.clear();
        deviceNames.clear();

        if (data is Map && data["sensors"] != null) {
          sensorsSet = _parseSensors(data["sensors"].toString());
        } else {
          sensorsSet = {};
        }

        if (data is Map && data["timeout"] != null) {
          final t = data["timeout"];
          if (t is int) timeoutSec = t;
          if (t is double) timeoutSec = t.toInt();
          if (t is String) timeoutSec = int.tryParse(t) ?? timeoutSec;
          if (timeoutSec < 1) timeoutSec = 1;
        }

        if (data is Map) {
          data.forEach((key, value) {
            if (value is bool) {
              relayStatus[key] = value;
              deviceNames[key] = _prefs.getString(key) ?? key;
            }
          });
        }
      }

      loading = false;
      notifyListeners();
    } catch (_) {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> toggleRelay(String key, bool value) async {
    final url = Uri.parse("$databaseUrl/$key.json");

    await http.put(url, body: jsonEncode(value));

    relayStatus[key] = value;
    notifyListeners();
  }

  Future<void> toggleSensorForRelay(String key) async {
    final normalized = key.toLowerCase();

    final newSet = Set<String>.from(sensorsSet);
    if (newSet.contains(normalized)) {
      newSet.remove(normalized);
    } else {
      newSet.add(normalized);
    }

    final sensorsString = newSet.join(',');

    final url = Uri.parse("$databaseUrl/sensors.json");
    await http.put(url, body: jsonEncode(sensorsString));

    sensorsSet = newSet;
    notifyListeners();
  }

  Future<void> setTimeoutSeconds(int seconds) async {
    if (seconds < 1) seconds = 1;

    final url = Uri.parse("$databaseUrl/timeout.json");
    await http.put(url, body: jsonEncode(seconds));

    timeoutSec = seconds;
    notifyListeners();
  }

  Future<void> updateDeviceName(String key, String newName) async {
    if (newName.isEmpty) return;
    await _prefs.setString(key, newName);
    deviceNames[key] = newName;
    notifyListeners();
  }

  void toggleAll(bool value) {
    for (final key in relayStatus.keys) {
      toggleRelay(key, value);
    }
  }

  Set<String> _parseSensors(String raw) {
    final cleaned = raw
        .toLowerCase()
        .replaceAll('"', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll(' ', '');
    if (cleaned.isEmpty) return {};
    return cleaned.split(',').where((e) => e.trim().isNotEmpty).toSet();
  }
}

