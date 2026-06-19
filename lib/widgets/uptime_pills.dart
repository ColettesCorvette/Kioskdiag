import 'package:flutter/material.dart';

import '../theme.dart';

/// Liste de pastilles d'uptime 
class UptimePills extends StatelessWidget {
  const UptimePills({super.key, required this.uptime});

  final Duration uptime;

  @override
  Widget build(BuildContext context) {
    final days = uptime.inDays;
    final hours = uptime.inHours % 24;
    final minutes = uptime.inMinutes % 60;
    final seconds = uptime.inSeconds % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(days, 'JOURS', DiagColors.pillDays),
        const SizedBox(height: 8),
        _row(hours, 'HEURES', DiagColors.pillHours),
        const SizedBox(height: 8),
        _row(minutes, 'MINUTES', DiagColors.pillMinutes),
        const SizedBox(height: 8),
        _row(seconds, 'SECONDES', DiagColors.pillSeconds),
      ],
    );
  }

  Widget _row(int value, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF222428),
          ),
        ),
      ],
    );
  }
}
