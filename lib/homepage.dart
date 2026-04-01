import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // ✅ NEW (for CupertinoTimerPicker)
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String databaseUrl =
    "https://esp32-smart-home-5643e-default-rtdb.firebaseio.com/";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, bool> relayStatus = {};
  Map<String, String> deviceNames = {};
  bool editMode = false;
  bool loading = true;

  late SharedPreferences prefs;

  // holds which relays are controlled by sensors (e.g. {"relay2","relay4"})
  Set<String> sensorsSet = {};

  // timeout in seconds stored in Firebase at /timeout
  int timeoutSec = 60;

  @override
  void initState() {
    super.initState();
    _initPrefsAndFetch();
  }

  Future<void> _initPrefsAndFetch() async {
    prefs = await SharedPreferences.getInstance();
    await _fetchDevicesFromDatabase();
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

  String _formatTimeoutLabel(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    if (h > 0) return "${h}h ${m}m ${s}s";
    if (m > 0) return "${m}m ${s}s";
    return "${s}s";
  }

  Future<void> _fetchDevicesFromDatabase() async {
    try {
      final url = Uri.parse("$databaseUrl/.json");
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != "null") {
        final data = jsonDecode(response.body);

        setState(() {
          relayStatus = {};
          deviceNames = {};

          if (data is Map && data["sensors"] != null) {
            sensorsSet = _parseSensors(data["sensors"].toString());
          } else {
            sensorsSet = {};
          }

          // ✅ read timeout
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
                deviceNames[key] = prefs.getString(key) ?? key;
              }
            });
          }

          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _toggleRelay(String key, bool value) async {
    final url = Uri.parse("$databaseUrl/$key.json");

    await http.put(url, body: jsonEncode(value));

    setState(() {
      relayStatus[key] = value;
    });
  }

  Future<void> _toggleSensorForRelay(String key) async {
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

    setState(() {
      sensorsSet = newSet;
    });
  }

  Future<void> _setTimeoutSeconds(int seconds) async {
    if (seconds < 1) seconds = 1;

    final url = Uri.parse("$databaseUrl/timeout.json");
    await http.put(url, body: jsonEncode(seconds));

    setState(() {
      timeoutSec = seconds;
    });
  }

  Future<void> _showTimeoutPicker() async {
    Duration selected = Duration(seconds: timeoutSec);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: 320,
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Text(
                  "Set Timeout (H : M : S)",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(brightness: Brightness.dark),
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hms,
                      initialTimerDuration: Duration(seconds: timeoutSec),
                      onTimerDurationChanged: (d) {
                        selected = d;
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final secs = selected.inSeconds;
                            await _setTimeoutSeconds(secs);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleAll(bool value) {
    relayStatus.keys.forEach((key) {
      _toggleRelay(key, value);
    });
  }

  void _editDeviceName(String key) async {
    final controller = TextEditingController(text: deviceNames[key]);
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Edit Device Name"),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  await prefs.setString(key, newName);
                  setState(() {
                    deviceNames[key] = newName;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final devices = relayStatus.keys.map((key) {
      return {
        "key": key,
        "name": deviceNames[key]!,
        "status": relayStatus[key]! ? "Online" : "Offline",
        "isOn": relayStatus[key]!,
      };
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xff121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.location_pin, size: 20),
                          SizedBox(width: 10),
                          Text("Ask Chromecast"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: Colors.black87,
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage("assets/MP.png"),
                  ),
                ],
              ),
              if (MediaQuery.of(context).size.height > 500)
                const SizedBox(height: 20),

              if (MediaQuery.of(context).size.height > 500)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      tabButton("Favorites", Icons.favorite, selected: true),
                      const SizedBox(width: 12),
                      tabButton("Grid", Icons.grid_view),
                      const SizedBox(width: 12),
                      tabButton("Lights", Icons.lightbulb),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    child: Wrap(
                      children: List.generate(devices.length, (i) {
                        final device = devices[i];
                        final String key = device["key"] as String;
                        final String name = device["name"] as String;
                        final String status = device["status"] as String;
                        final bool isOn = device["isOn"] as bool;

                        final bool isSensorControlled =
                        sensorsSet.contains(key.toLowerCase());

                        return SizedBox(
                          height: 100,
                          width: 180,
                          child: GestureDetector(
                            // ✅ Reverted: Tap toggles manual ON/OFF always
                            onTap: () {
                              if (editMode) {
                                _editDeviceName(key);
                                return;
                              }
                              _toggleRelay(key, !isOn);
                            },

                            // ✅ Reverted: Long press toggles sensor mode
                            onLongPress: () {
                              _toggleSensorForRelay(key);
                            },

                            child: Stack(
                              children: [
                                DeviceCard(
                                  name: name,
                                  status: status,
                                  isOn: isOn,
                                  isSensorControlled: isSensorControlled,
                                ),
                                if (editMode)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    bottomButton(
                      editMode ? "Done" : "Edit",
                      Icons.edit,
                      onTap: () => setState(() => editMode = !editMode),
                    ),
                    const SizedBox(width: 5),
                    bottomButton(
                      "ALL ON",
                      Icons.power,
                      onTap: () => _toggleAll(true),
                    ),
                    const SizedBox(width: 5),
                    bottomButton(
                      "ALL OFF",
                      Icons.power_off,
                      onTap: () => _toggleAll(false),
                    ),
                    const SizedBox(width: 5),
                    bottomButton(
                      "TIMEOUT (${_formatTimeoutLabel(timeoutSec)})",
                      Icons.timer,
                      onTap: _showTimeoutPicker,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black87,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Activity"),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_mode),
            label: "Automations",
          ),
        ],
      ),
    );
  }

  Widget tabButton(String title, IconData icon, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? Colors.blueGrey.shade700 : Colors.black87,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
    );
  }

  Widget bottomButton(String title, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final String name;
  final String status;
  final bool isOn;
  final bool isSensorControlled;

  const DeviceCard({
    super.key,
    required this.name,
    required this.status,
    required this.isOn,
    required this.isSensorControlled,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isSensorControlled
        ? const Color(0xff02615c)
        : (isOn ? Colors.blueGrey : Colors.grey.shade900);

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(Icons.lightbulb,
              size: 30, color: isOn ? Colors.yellow : Colors.white70),
          title: Text(name, style: const TextStyle(fontSize: 16)),
          subtitle: Text(status, style: const TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }
}