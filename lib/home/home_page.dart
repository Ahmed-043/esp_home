import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'home_controller.dart';
import 'widgets/device_card.dart';
import 'widgets/home_buttons.dart';

const _primary = Color(0xFF00E5FF);
const _secondary = Color(0xFF1DE9B6);
const _bgStart = Color(0xFF0F172A);
const _bgEnd = Color(0xFF111827);

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.controller,
    this.initController = true,
    this.openTimeoutPickerOnStart = false,
  });

  final HomeController? controller;
  final bool initController;
  final bool openTimeoutPickerOnStart;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final HomeController _controller;
  bool _openedTimeoutOnStart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = widget.controller ?? HomeController();
    if (widget.initController && !_controller.isInitialized) {
      _controller.init();
    }
    if (widget.openTimeoutPickerOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openTimeoutPickerOnStartIfNeeded();
      });
    }
  }

  void _openTimeoutPickerOnStartIfNeeded() {
    if (!mounted || _openedTimeoutOnStart || !widget.openTimeoutPickerOnStart) {
      return;
    }
    _openedTimeoutOnStart = true;
    _showTimeoutPicker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _controller.pauseNonEssentialWork();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _controller.resumeNonEssentialWork();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showTimeoutPicker() async {
    Duration selected = Duration(seconds: _controller.timeoutSec);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_bgStart, _bgEnd],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3300E5FF),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SizedBox(
              height: 340,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Set Timeout (H : M : S)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: CupertinoTheme(
                      data: const CupertinoThemeData(brightness: Brightness.dark),
                      child: CupertinoTimerPicker(
                        mode: CupertinoTimerPickerMode.hms,
                        initialTimerDuration:
                            Duration(seconds: _controller.timeoutSec),
                        onTimerDurationChanged: (d) {
                          selected = d;
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primary, _secondary],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x3300E5FF),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.black,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () async {
                                final secs = selected.inSeconds;
                                await _controller.setTimeoutSeconds(secs);
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text('Save'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editDeviceName(String key) async {
    final controller =
        TextEditingController(text: _controller.deviceNames[key]);
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: _bgStart,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          title: const Text(
            'Edit Device Name',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: _bgEnd,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                await _controller.updateDeviceName(key, newName);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: _secondary)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final devices = _controller.relayStatus.keys.map((key) {
          return {
            'key': key,
            'name': _controller.deviceNames[key] ?? key,
            'status': _controller.relayStatus[key]! ? 'Online' : 'Offline',
            'isOn': _controller.relayStatus[key]!,
          };
        }).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_bgStart, _bgEnd],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_bgStart, _bgEnd],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                border:
                                    Border.all(color: Colors.white.withOpacity(0.1)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x2200E5FF),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.location_pin, size: 20),
                                  SizedBox(width: 10),
                                  Text('Ask Chromecast'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primary, _secondary],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x3300E5FF),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {},
                                customBorder: const CircleBorder(),
                                splashColor: Colors.black.withOpacity(0.2),
                                child: const CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  child: Icon(Icons.add, color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            backgroundImage: const AssetImage('assets/MP.png'),
                          ),
                        ],
                      ),
                    ),

                    if (MediaQuery.of(context).size.height > 500)
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              tabButton('Favorites', Icons.favorite,
                                  selected: true, onTap: () {}),
                              const SizedBox(width: 12),
                              tabButton('Grid', Icons.grid_view, onTap: () {}),
                              const SizedBox(width: 12),
                              tabButton('Lights', Icons.lightbulb, onTap: () {}),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: List.generate(devices.length, (i) {
                              final device = devices[i];
                              final String key = device['key'] as String;
                              final String name = device['name'] as String;
                              final String status = device['status'] as String;
                              final bool isOn = device['isOn'] as bool;

                              final bool isSensorControlled =
                                  _controller.sensorsSet
                                      .contains(key.toLowerCase());

                              return SizedBox(
                                height: 80,
                                width: 180,
                                child: Stack(
                                  children: [
                                    DeviceCard(
                                      name: name,
                                      status: status,
                                      isOn: isOn,
                                      isSensorControlled: isSensorControlled,
                                    ),
                                    Positioned.fill(
                                      child: Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(22),
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                          splashColor: _primary.withOpacity(0.3),
                                          highlightColor: _primary.withOpacity(0.1),
                                          focusColor: _primary.withOpacity(0.2),
                                          hoverColor: _primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(22),
                                          onTap: () {
                                            if (_controller.editMode) {
                                              _editDeviceName(key);
                                              return;
                                            }
                                            _controller.toggleRelay(key, !isOn);
                                          },
                                          onLongPress: () {
                                            _controller.toggleSensorForRelay(key);
                                          },
                                        ),
                                      ),
                                    ),
                                    if (_controller.editMode)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: IgnorePointer(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            child: const Icon(
                                              Icons.edit,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                    if (_controller.loading && devices.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Center(
                          child: Text(
                            'Loading devices…',
                            style: TextStyle(color: Colors.white.withOpacity(0.6)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0,horizontal: 8),
                        child: Row(
                          children: [

                            bottomButton(
                              'TIMEOUT (${_controller.formatTimeoutLabel(_controller.timeoutSec)})',
                              Icons.timer,
                              onTap: _showTimeoutPicker,
                            ),

                            const SizedBox(width: 5),
                            bottomButton(
                              'ALL ON',
                              Icons.power,
                              onTap: () => _controller.toggleAll(true),
                            ),
                            const SizedBox(width: 5),
                            bottomButton(
                              'ALL OFF',
                              Icons.power_off,
                              onTap: () => _controller.toggleAll(false),
                            ),
                            const SizedBox(width: 5),bottomButton(
                              _controller.editMode ? 'Done' : 'Edit',
                              Icons.edit,
                              onTap: () =>
                                  _controller.setEditMode(!_controller.editMode),
                            ),


                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: const Color(0xFF0B1220),
            selectedItemColor: _primary,
            unselectedItemColor: Colors.white60,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Activity'),
              BottomNavigationBarItem(

                icon: Icon(Icons.auto_mode),
                label: 'Automations',
              ),
            ],
          ),
        );
      },
    );
  }
}
