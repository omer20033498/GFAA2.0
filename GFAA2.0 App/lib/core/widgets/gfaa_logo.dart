import 'package:flutter/material.dart';

/// GFAA horizontal lockup, used at the top of auth screens. Swap the asset
/// for a transparent/vector export if/when one is supplied.
class GfaaLogo extends StatelessWidget {
  const GfaaLogo({super.key, this.height = 40});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/logo_horizontal.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
