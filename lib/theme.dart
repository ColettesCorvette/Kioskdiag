import 'package:flutter/material.dart';

/// Palette de l'app de diagnostic calée sur la maquette Figma.
class DiagColors {
  static const background = Color(0xFFF6F7F9);
  static const title = Color(0xFF1C8AD6);
  static const red = Color(0xFFE0554F);

  // Liserés colorés en haut des cartes.
  static const accentUptime = Color(0xFFF5A623);
  static const accentDisk = Color(0xFF54B948);
  static const accentMemory = Color(0xFF9C27B0);
  static const accentCpu = Color(0xFFE0554F);

  static const cpuLine = Color(0xFF5B9BD5);

  static const diskTrack = Color(0xFFE6E8EB);
  static const diskArc = Color(0xFF2A93E0);

  static const memoryLine = Color(0xFF9C27B0);

  // Pastilles d'uptime, du plus clair au plus foncé.
  static const pillDays = Color(0xFF9BD4F2);
  static const pillHours = Color(0xFF49ABE3);
  static const pillMinutes = Color(0xFF1E7AC8);
  static const pillSeconds = Color(0xFF0E4C8C);

  static const textMuted = Color(0xFF6B7280);
}
