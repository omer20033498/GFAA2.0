import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Custom fonts (Perpetua, Ordine, Helvetica per CLAUDE.md) aren't available
/// as asset files yet, so this uses the platform default font family until
/// those are supplied — but the sizing/spacing/weight below is tuned now to
/// approximate the brand's intended feel (generously spaced, unhurried
/// serif headings; warm, open subheads) so screens don't need to change
/// again once the real font files land.
ThemeData buildAppTheme() {
  // Explicit ColorScheme rather than ColorScheme.fromSeed — the seed
  // algorithm generates its own tonal palette for slots we don't set
  // directly (secondaryContainer, tertiary, outline, etc.), and from a
  // green seed that algorithm tends to drift toward blue/violet, which is
  // exactly the "bluish/lavender" cast the client asked to remove. Pinning
  // every slot to our own palette keeps the whole app on-brand, including
  // default Material widgets we haven't explicitly styled.
  const colorScheme = ColorScheme.light(
    surface: AppColors.offWhite,
    onSurface: AppColors.nearBlack,
    primary: AppColors.deepGreen,
    onPrimary: Colors.white,
    primaryContainer: AppColors.softSage,
    onPrimaryContainer: AppColors.deepGreen,
    secondary: AppColors.sageGreen,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.softSage,
    onSecondaryContainer: AppColors.deepGreen,
    tertiary: AppColors.sageGreen,
    onTertiary: Colors.white,
    outline: AppColors.border,
    outlineVariant: AppColors.border,
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
      color: AppColors.secondaryText,
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
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.deepGreen.withValues(alpha: 0.4),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.deepGreen,
        backgroundColor: AppColors.coolWhite,
        side: const BorderSide(color: AppColors.deepGreen),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
  );
}
