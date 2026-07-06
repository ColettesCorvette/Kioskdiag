import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// Graphe de perf dessiné à la main courbe et aire.
/// Sert pour la mémoire comme pour le CPU.
class PerfGraph extends StatelessWidget {
  const PerfGraph({
    super.key,
    required this.series,
    required this.maxValue,
    required this.lineColor,
    required this.topRightLabel,
    required this.bottomRightLabel,
    this.height = 150,
  });

  final List<double> series;
  final double maxValue;
  final Color lineColor;

  /// Étiquette en haut à droite
  final String topRightLabel;

  /// Étiquette en bas à droite
  final String bottomRightLabel;

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GraphPainter(series, maxValue, lineColor)),
          ),
          Positioned(top: 4, right: 6, child: Text(topRightLabel, style: _axis)),
          const Positioned(
            left: 6,
            bottom: 4,
            child: Text('60 secondes', style: _axis),
          ),
          Positioned(
            right: 6,
            bottom: 4,
            child: Text(bottomRightLabel, style: _axis),
          ),
        ],
      ),
    );
  }

  static const _axis = TextStyle(fontSize: 12, color: DiagColors.textMuted);
}

class _GraphPainter extends CustomPainter {
  _GraphPainter(this.series, this.maxValue, this.lineColor);

  final List<double> series;
  final double maxValue;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFFD9DCE1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    if (series.length < 2 || maxValue <= 0) return;

    double x(int i) => size.width * i / (series.length - 1);
    double y(double v) => size.height * (1 - (v / maxValue).clamp(0, 1));

    final line = Path()..moveTo(x(0), y(series[0]));
    for (var i = 1; i < series.length; i++) {
      line.lineTo(x(i), y(series[i]));
    }

    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = lineColor.withValues(alpha: 0.14));

    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      !listEquals(old.series, series) ||
      old.maxValue != maxValue ||
      old.lineColor != lineColor;
}
