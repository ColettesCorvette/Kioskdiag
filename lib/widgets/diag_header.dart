import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// En-tête logo,titre/sous-titre bouton de rotation de l'écran.
class DiagHeader extends StatelessWidget {
  const DiagHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onToggleOrientation,
    required this.onResetOrientation,
    required this.onQuit,
  });

  final String title;
  final String subtitle;

  /// Pression courte rotation d'un quart de tour.
  final VoidCallback onToggleOrientation;

  /// Appui long retour à l'orientation par défaut.
  final VoidCallback onResetOrientation;

  /// Ferme kioskdiag et revient à l'affichage client.
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Logo provisoire à remplacer par le vrai asset.
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0xFF1C8AD6),
                  Color(0xFF54B948),
                  Color(0xFFF5A623),
                  Color(0xFFE0554F),
                  Color(0xFF9C27B0),
                  Color(0xFF1C8AD6),
                ],
              ),
            ),
            child: const Center(
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(Icons.sync_alt, size: 18, color: DiagColors.title),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: DiagColors.title,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222428),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Quitter : retour à l'affichage client kioskview.
          IconButton(
            tooltip: 'Quitter',
            icon: const Icon(Icons.close, color: DiagColors.title),
            iconSize: 32,
            // Cible tactile élargie : dalle capacitive peu précise sur les bords.
            constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
            onPressed: onQuit,
          ),
          const SizedBox(width: 4),
          // Bouton de rotation de l'écran.
          Material(
            color: DiagColors.red,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onToggleOrientation,
              onLongPress: onResetOrientation,
              child: SizedBox(
                width: 64,
                height: 64,
                child: Center(
                  child: Transform.rotate(
                    angle: math.pi / 4, // flèche en diagonale
                    child: const Icon(
                      Icons.swap_vert,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
