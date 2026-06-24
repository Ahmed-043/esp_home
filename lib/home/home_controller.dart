import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
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

  // Desktop specific (REST API)
  Timer? _refreshTimer;

  // Mobile/Web specific (SDK)
  StreamSubscription<DatabaseEvent>? _subscription;
  //final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  DatabaseReference get _dbRef => FirebaseDatabase.instance.ref();
  // holds which relays are controlled by sensors (e.g. {"relay2","relay4"})
  Set<String> sensorsSet = {};

  // timeout in seconds stored in Firebase at /timeout
  int timeoutSec = 60;

  bool get _isDesktop => !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
       defaultTargetPlatform == TargetPlatform.linux ||
       defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _prefs = await SharedPreferences.getInstance();

    if (_isDesktop) {
      // Desktop: Polling via REST API
      await fetchDevicesFromDatabase();
      _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        fetchDevicesFromDatabase(isSilent: true);
      });
    } else {
      // Mobile/Web: Real-time via SDK
      _startListeningSDK();
    }
  }

  void _startListeningSDK() {
    _subscription = _dbRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        _processDatabaseData(data);
      }
      loading = false;
      notifyListeners();
    }, onError: (error) {
      debugPrint("Firebase SDK Error: $error");
      loading = false;
      notifyListeners();
    });
  }

  void _processDatabaseData(Map data) {
    // Parse sensors
    if (data["sensors"] != null) {
      sensorsSet = _parseSensors(data["sensors"].toString());
    } else {
      sensorsSet = {};
    }

    // Parse timeout
    if (data["timeout"] != null) {
      final t = data["timeout"];
      if (t is int) timeoutSec = t;
      else if (t is double) timeoutSec = t.toInt();
      else if (t is String) timeoutSec = int.tryParse(t) ?? timeoutSec;
      if (timeoutSec < 1) timeoutSec = 1;
    }

    // Parse relays
    relayStatus.clear();
    data.forEach((key, value) {
      if (value is bool) {
        relayStatus[key] = value;
        deviceNames[key] = _prefs.getString(key) ?? key;
      }
    });
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

  /// REST API implementation for Desktop
  Future<void> fetchDevicesFromDatabase({bool isSilent = false}) async {
    try {
      final String baseUrl = databaseUrl.endsWith('/')
          ? databaseUrl.substring(0, databaseUrl.length - 1)
          : databaseUrl;

      final url = Uri.parse("$baseUrl/.json?cb=${DateTime.now().millisecondsSinceEpoch}");
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != "null") {
        final data = jsonDecode(response.body);
        if (data is Map) {
          _processDatabaseData(data);
        }
      }

      loading = false;
      notifyListeners();
    } catch (e) {
      if (!isSilent) {
        debugPrint("Fetch error: $e");
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> toggleRelay(String key, bool value) async {
    try {
      // Optimistic update
      relayStatus[key] = value;
      notifyListeners();

      if (_isDesktop) {
        final String baseUrl = databaseUrl.endsWith('/')
            ? databaseUrl.substring(0, databaseUrl.length - 1)
            : databaseUrl;
        final url = Uri.parse("$baseUrl/$key.json");
        await http.put(url, body: jsonEncode(value));
      } else {
        await _dbRef.child(key).set(value);
      }
    } catch (e) {
      debugPrint("Toggle error: $e");
      if (_isDesktop) fetchDevicesFromDatabase(isSilent: true);
    }
  }

  Future<void> toggleSensorForRelay(String key) async {
    try {
      final normalized = key.toLowerCase();
      final newSet = Set<String>.from(sensorsSet);
      if (newSet.contains(normalized)) {
        newSet.remove(normalized);
      } else {
        newSet.add(normalized);
      }

      sensorsSet = newSet;
      notifyListeners();

      final sensorsString = newSet.join(',');

      if (_isDesktop) {
        final String baseUrl = databaseUrl.endsWith('/')
            ? databaseUrl.substring(0, databaseUrl.length - 1)
            : databaseUrl;
        final url = Uri.parse("$baseUrl/sensors.json");
        await http.put(url, body: jsonEncode(sensorsString));
      } else {
        await _dbRef.child("sensors").set(sensorsString);
      }
    } catch (e) {
      debugPrint("Toggle sensor error: $e");
    }
  }

  Future<void> setTimeoutSeconds(int seconds) async {
    try {
      if (seconds < 1) seconds = 1;
      timeoutSec = seconds;
      notifyListeners();

      if (_isDesktop) {
        final String baseUrl = databaseUrl.endsWith('/')
            ? databaseUrl.substring(0, databaseUrl.length - 1)
            : databaseUrl;
        final url = Uri.parse("$baseUrl/timeout.json");
        await http.put(url, body: jsonEncode(seconds));
      } else {
        await _dbRef.child("timeout").set(seconds);
      }
    } catch (e) {
      debugPrint("Set timeout error: $e");
    }
  }

  Future<void> updateDeviceName(String key, String newName) async {
    if (newName.isEmpty) return;
    await _prefs.setString(key, newName);
    deviceNames[key] = newName;
    notifyListeners();
  }

  void toggleAll(bool value) {
    for (final key in relayStatus.keys) {
      relayStatus[key] = value;
    }
    notifyListeners();

    if (_isDesktop) {
      final String baseUrl = databaseUrl.endsWith('/')
          ? databaseUrl.substring(0, databaseUrl.length - 1)
          : databaseUrl;
      for (final key in relayStatus.keys) {
        final url = Uri.parse("$baseUrl/$key.json");
        http.put(url, body: jsonEncode(value));
      }
    } else {
      final Map<String, dynamic> updates = {};
      for (final key in relayStatus.keys) {
        updates[key] = value;
      }
      if (updates.isNotEmpty) {
        _dbRef.update(updates);
      }
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

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
