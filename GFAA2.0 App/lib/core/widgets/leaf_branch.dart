import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A soft decorative sprig — stem + a handful of leaf blobs — used as brand
/// flourish (profile drawer header, auth screen corners). Drawn rather than
/// an image asset since no vector illustration export exists yet; kept
/// intentionally simple/abstract so it doesn't need to match a specific
/// reference illustration pixel-for-pixel.
class LeafBranch extends StatelessWidget {
  const LeafBranch({super.key, this.width = 140, this.height = 70, this.mirrored = false});

  final double width;
  final double height;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final painter = CustomPaint(size: Size(width, height), painter: _LeafBranchPainter());
    return mirrored ? Transform.flip(flipX: true, child: painter) : painter;
  }
}

class _LeafBranchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = AppColors.sageGreen.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final stemPath = Path()
      ..moveTo(0, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.95, size.width, size.height * 0.15);
    canvas.drawPath(stemPath, stemPaint);

    final leafPaint = Paint()..style = PaintingStyle.fill;
    final leafPositions = [0.12, 0.3, 0.48, 0.64, 0.8, 0.94];
    for (var i = 0; i < leafPositions.length; i++) {
      final t = leafPositions[i];
      final point = _pointOnQuadratic(
        Offset(0, size.height * 0.85),
        Offset(size.width * 0.5, size.height * 0.95),
        Offset(size.width, size.height * 0.15),
        t,
      );
      final leafSize = size.height * (0.16 + 0.02 * (i.isEven ? 1 : 0));
      leafPaint.color = AppColors.sageGreen.withValues(alpha: 0.28 + 0.06 * (i % 3));
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(-0.6 + i * 0.22);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: leafSize, height: leafSize * 0.55), leafPaint);
      canvas.restore();
    }
  }

  Offset _pointOnQuadratic(Offset p0, Offset p1, Offset p2, double t) {
    final x = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
    final y = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
