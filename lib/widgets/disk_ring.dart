import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Anneau d'espace disque dessiné au CustomPaint, avec l'espace restant au
/// centre.
class DiskRing extends StatelessWidget {
  const DiskRing({
    super.key,
    required this.usedFraction,
    required this.freeLabel,
    this.size = 130,
  });

  /// Part utilisée, de 0 à 1 : portion bleue de l'anneau.
  final double usedFraction;

  /// Texte central
  final String freeLabel;

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(usedFraction),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                freeLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222428),
                ),
              ),
              const Text(
                'Restants',
                style: TextStyle(fontSize: 13, color: DiagColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.usedFraction);

  final double usedFraction;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 15.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final track = Paint()
      ..color = DiagColors.diskTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final arc = Paint()
      ..color = DiagColors.diskArc
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    // Fond complet puis arc de la part utilisée à partir du haut.
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * usedFraction, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.usedFraction != usedFraction;
}
