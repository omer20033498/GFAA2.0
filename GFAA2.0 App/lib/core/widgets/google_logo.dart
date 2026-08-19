import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Google's four-colour "G" mark, drawn rather than an image asset (no
/// asset pipeline for third-party logos exists yet). An approximation of
/// the ring-plus-bar glyph, not a pixel-exact reproduction of Google's
/// official asset — close enough to read as "Google" at button size.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _GoogleGPainter()));
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Four quarter-arcs, leaving a gap on the right for the bar to plug into.
    const gap = 0.18;
    final sweep = (math.pi * 2 / 4) - gap;

    void arc(double startAngle, Color color) {
      ringPaint.color = color;
      canvas.drawArc(rect, startAngle, sweep, false, ringPaint);
    }

    arc(-math.pi / 2 + gap / 2, const Color(0xFF4285F4)); // blue, top-right
    arc(0 + gap / 2, const Color(0xFF34A853)); // green, bottom-right
    arc(math.pi / 2 + gap / 2, const Color(0xFFFBBC05)); // yellow, bottom-left
    arc(math.pi + gap / 2, const Color(0xFFEA4335)); // red, top-left

    // The bar plugging into the ring on the right side.
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx - strokeWidth * 0.1, center.dy - strokeWidth / 2, radius - center.dx + strokeWidth,
          strokeWidth),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
