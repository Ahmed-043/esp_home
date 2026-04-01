import 'package:flutter/material.dart';

const _primary = Color(0xFF00E5FF);
const _secondary = Color(0xFF1DE9B6);

Widget tabButton(String title, IconData icon, {bool selected = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    decoration: BoxDecoration(
      gradient: selected
          ? const LinearGradient(colors: [_primary, _secondary])
          : null,
      color: selected ? null : const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
      boxShadow: selected
          ? const [
              BoxShadow(
                color: Color(0x3300E5FF),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ]
          : [],
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: selected ? Color(0xFF3B595C) : Colors.white),
        const SizedBox(width: 8),
        Text(title,style: TextStyle(color: selected ? Color(0xFF3B595C) : Colors.white),),
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
        gradient: const LinearGradient(
          stops: [0.0, 0.2],
          colors: [Color(0xFF0F172A), Color(0xFF111827)],
        ),
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2200E5FF),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    ),
  );
}
