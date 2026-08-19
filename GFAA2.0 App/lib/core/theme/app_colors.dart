import 'package:flutter/material.dart';

/// GFAA palette, updated 2026-08-19 to a warmer sage-based direction after
/// the client flagged the previous tones as reading too cool/clinical (the
/// old `coolWhite` #F4F6FC and Material 3's auto-generated tonal palette
/// both skewed bluish/lavender). A same-day follow-up then flagged that
/// `coolWhite` and `offWhite` had ended up too close in tone, leaving cards
/// with almost no contrast against the page — `coolWhite`/`softSage` were
/// deepened slightly to fix that; see `AppCard` (core/widgets/app_card.dart)
/// for the border + soft shadow that reinforces the same contrast. Exact
/// hex values from the client's spec — don't drift these without asking.
/// `neonYellow` isn't part of that spec but wasn't targeted for removal
/// either — kept as the rare, sparing accent the original GFAA Brand Style
/// Guide calls for (never a button colour, never a fill).
abstract final class AppColors {
  /// Very light sage background — primary app background.
  static const offWhite = Color(0xFFF3F6F0);

  /// Card background — deliberately a step darker than [offWhite] so cards
  /// actually read as raised surfaces, not just same-toned rectangles.
  static const coolWhite = Color(0xFFE9EFE7);

  /// Secondary sage.
  static const sageGreen = Color(0xFF8FAF9A);

  /// Soft sage tint — icon circles, selected states, light fills.
  static const softSage = Color(0xFFD5E4D3);

  /// Primary brand / action green — primary buttons, headings, selected nav.
  static const deepGreen = Color(0xFF355C45);

  /// Main text.
  static const nearBlack = Color(0xFF1F2923);

  /// Secondary/muted text and icons — use this instead of `nearBlack` at
  /// reduced opacity, so muted colour stays on-palette rather than an
  /// arbitrary alpha blend.
  static const secondaryText = Color(0xFF5F6962);

  /// Borders and dividers.
  static const border = Color(0xFFD8DED7);

  /// Rare accent only — highlight a single word/moment, never a button or
  /// large fill (see CLAUDE.md brand guide).
  static const neonYellow = Color(0xFFE6FE54);
}
