import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Pill-shaped field styling for the auth screens (login/register) — kept
/// local to these screens rather than changed globally in the app theme,
/// since the rest of the app's fields aren't part of this redesign pass.
InputDecoration authFieldDecoration({
  required IconData icon,
  required String hint,
  Widget? suffixIcon,
}) {
  final radius = BorderRadius.circular(28);
  OutlineInputBorder border({Color color = Colors.transparent, double width = 1}) {
    return OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: color, width: width));
  }

  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 20, color: AppColors.secondaryText),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.coolWhite,
    contentPadding: const EdgeInsets.symmetric(vertical: 18),
    border: border(),
    enabledBorder: border(),
    focusedBorder: border(color: AppColors.sageGreen, width: 1.6),
    errorBorder: border(color: Colors.red.shade300, width: 1.4),
    focusedErrorBorder: border(color: Colors.red.shade400, width: 1.6),
  );
}

/// A headline with one word picked out with the brand's rare neon-yellow
/// underline accent (see CLAUDE.md — used sparingly, never as a fill
/// colour). [text] must contain [accentWord] exactly once.
Widget accentHeadline(String text, String accentWord, TextStyle? style) {
  final index = text.indexOf(accentWord);
  assert(index != -1, '"$accentWord" not found in "$text"');
  return Text.rich(
    TextSpan(
      style: style,
      children: [
        TextSpan(text: text.substring(0, index)),
        TextSpan(
          text: accentWord,
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: AppColors.neonYellow,
            decorationThickness: 2.6,
          ),
        ),
        TextSpan(text: text.substring(index + accentWord.length)),
      ],
    ),
  );
}
