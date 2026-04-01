import 'package:flutter/material.dart';

const _primary = Color(0xFF00E5FF);
const _secondary = Color(0xFF13B38B);

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
    final Color baseColor = isSensorControlled
        ? const Color(0xFF0B3B3A)
        : (isOn ? const Color(0xFF1F2937) : const Color(0xFF0F172A));
    final List<BoxShadow> glow = isOn || isSensorControlled
        ? const [
            BoxShadow(
              color: Color(0x3300E5FF),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ]
        : const [];

    final statusText = [
      if (!isOn && !isSensorControlled) 'Offline',
      if (isOn) 'Online',
      if (isSensorControlled) 'Auto',
    ].join(' ');

    return Container(
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all( color: isOn ? _primary : Colors.white.withOpacity(0.08)),
        boxShadow: glow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: ListTile(
          contentPadding: const EdgeInsets.only(
            left: 12, right : 12,
            top: 4, bottom : 4
          ),
          splashColor: _primary,
          titleAlignment: .center,
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,

              //border: Border.all(width:1,color: isOn ? _primary : Colors.white.withOpacity(0.08)),
              gradient: isOn || isSensorControlled
                  ? const LinearGradient(colors: [_primary, _secondary])
                  : LinearGradient(colors: [Colors.white, Colors.white.withOpacity(0.08)]),
              color:isSensorControlled
                  ? null
                  : Colors.white.withOpacity(0.08),
            ),
            child: Icon(
              Icons.lightbulb,
              size: 22,
              color: isOn
                  ? Color(0xFF04888C)
                  : Color(0xFF3B595C),
            ),
          ),
          title: Text(name, style: const TextStyle(fontSize: 16)),
          subtitle: Text(
              statusText,
            style: TextStyle(
              color: isOn || isSensorControlled
                  ? _secondary.withOpacity(0.8)
                  : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
