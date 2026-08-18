import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Custom fonts (Perpetua, Ordine, Helvetica per CLAUDE.md) aren't available
/// as asset files yet, so this uses the platform default font family until
/// those are supplied — but the sizing/spacing/weight below is tuned now to
/// approximate the brand's intended feel (generously spaced, unhurried
/// serif headings; warm, open subheads) so screens don't need to change
/// again once the real font files land.
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.sageGreen,
    brightness: Brightness.light,
    surface: AppColors.offWhite,
    primary: AppColors.sageGreen,
    secondary: AppColors.deepGreen,
    onSurface: AppColors.nearBlack,
  );

  const headingColor = AppColors.deepGreen;
  const bodyColor = AppColors.nearBlack;

  final textTheme = TextTheme(
    // Perpetua stand-in: headings and reflective long-form text.
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 1.3,
      letterSpacing: 0.2,
      fontWeight: FontWeight.w400,
      color: headingColor,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      height: 1.35,
      letterSpacing: 0.2,
      fontWeight: FontWeight.w400,
      color: headingColor,
    ),
    // Ordine stand-in: subheads, UI labels, section titles.
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.4,
      letterSpacing: 0.1,
      fontWeight: FontWeight.w500,
      color: bodyColor,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: bodyColor),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: bodyColor),
    // Helvetica stand-in: small captions / labels.
    labelSmall: TextStyle(
      fontSize: 12,
      letterSpacing: 0.6,
      fontWeight: FontWeight.w700,
      color: bodyColor.withValues(alpha: 0.7),
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.offWhite,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.offWhite,
      foregroundColor: AppColors.nearBlack,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.coolWhite,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.deepGreen,
        foregroundColor: AppColors.offWhite,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.2),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.deepGreen),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.coolWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      helperMaxLines: 2,
    ),
  );
}
