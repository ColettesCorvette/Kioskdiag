import 'package:flutter/material.dart';

import '../theme.dart';

/// Bascule Mémoire / Processeur la vue active est un pill coloré avec
/// libellé, l'autre une simple icône grise.
class PerfToggle extends StatelessWidget {
  const PerfToggle({
    super.key,
    required this.cpuSelected,
    required this.onChanged,
  });

  /// false = Mémoire, true = Processeur.
  final bool cpuSelected;

  /// Notifie la nouvelle sélection true pour Processeur.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pill(
          selected: !cpuSelected,
          icon: Icons.memory,
          label: 'Mémoire',
          accent: DiagColors.accentMemory,
          onTap: () => onChanged(false),
        ),
        const SizedBox(width: 10),
        _pill(
          selected: cpuSelected,
          icon: Icons.developer_board,
          label: 'Processeur',
          accent: DiagColors.accentCpu,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }

  Widget _pill({
    required bool selected,
    required IconData icon,
    required String label,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final color = selected ? accent : DiagColors.textMuted;
    return Material(
      color: selected ? accent.withValues(alpha: 0.12) : const Color(0xFFEDEFF2),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              if (selected) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
