import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Layered hills + a pale sun — closing flourish for the profile drawer.
/// Drawn rather than an image asset (see leaf_branch.dart for the same
/// reasoning); a calm horizon rather than a literal illustration match.
class MountainFooter extends StatelessWidget {
  const MountainFooter({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(painter: _MountainPainter()),
    );
  }
}

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sun
    final sunPaint = Paint()..color = const Color(0xFFF3C77A).withValues(alpha: 0.55);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.28), size.height * 0.16, sunPaint);

    void hill(double baseY, double amp, Color color) {
      final path = Path()..moveTo(0, size.height);
      path.lineTo(0, baseY);
      path.quadraticBezierTo(size.width * 0.25, baseY - amp, size.width * 0.5, baseY - amp * 0.3);
      path.quadraticBezierTo(size.width * 0.78, baseY + amp * 0.5, size.width, baseY - amp * 0.2);
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }

    hill(size.height * 0.62, size.height * 0.16, AppColors.sageGreen.withValues(alpha: 0.28));
    hill(size.height * 0.78, size.height * 0.14, AppColors.sageGreen.withValues(alpha: 0.4));
    hill(size.height * 0.92, size.height * 0.1, AppColors.sageGreen.withValues(alpha: 0.55));

    // A couple of small birds.
    final birdPaint = Paint()
      ..color = AppColors.deepGreen.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    void bird(Offset center) {
      final path = Path()
        ..moveTo(center.dx - 7, center.dy)
        ..quadraticBezierTo(center.dx - 3, center.dy - 5, center.dx, center.dy)
        ..quadraticBezierTo(center.dx + 3, center.dy - 5, center.dx + 7, center.dy);
      canvas.drawPath(path, birdPaint);
    }

    bird(Offset(size.width * 0.35, size.height * 0.18));
    bird(Offset(size.width * 0.46, size.height * 0.1));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
