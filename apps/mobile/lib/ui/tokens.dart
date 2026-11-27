import 'package:flutter/material.dart';

/// Design tokens copied once from docs/DESIGN.html (CSS variables `.light` and `.dark`, identical on
/// all 14 boards). Widgets read them through [AppPalette] on the theme, never as color literals.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.ink,
    required this.muted,
    required this.line,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.error,
    required this.meal1,
    required this.meal2,
    required this.meal3,
    required this.meal4,
    required this.proteinTint,
    required this.fatTint,
    required this.carbsTint,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color ink;
  final Color muted;
  final Color line;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color protein;
  final Color fat;
  final Color carbs;
  final Color error;

  /// Meal accents, used by the Diary from M3.
  final Color meal1;
  final Color meal2;
  final Color meal3;
  final Color meal4;
  final Color proteinTint;
  final Color fatTint;
  final Color carbsTint;

  static const light = AppPalette(
    background: Color(0xFFF7F1EC),
    surface: Color(0xFFFFFCF9),
    surfaceVariant: Color(0xFFEFE6DF),
    ink: Color(0xFF382C35),
    muted: Color(0xFF6A5963),
    line: Color(0xFFDDCFC6),
    primary: Color(0xFF74507A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEEDFE9),
    onPrimaryContainer: Color(0xFF472B4D),
    protein: Color(0xFF3F6652),
    fat: Color(0xFF8A5129),
    carbs: Color(0xFF93445A),
    error: Color(0xFF9E3B30),
    meal1: Color(0xFFF6E2BC),
    meal2: Color(0xFFDFE5CC),
    meal3: Color(0xFFE8D9E8),
    meal4: Color(0xFFF5D5C8),
    proteinTint: Color(0xFFE5EBDC),
    fatTint: Color(0xFFF8E6D4),
    carbsTint: Color(0xFFF6E0E0),
  );

  static const dark = AppPalette(
    background: Color(0xFF1D171A),
    surface: Color(0xFF2A2226),
    surfaceVariant: Color(0xFF392F34),
    ink: Color(0xFFF3E9EC),
    muted: Color(0xFFC9B7BF),
    line: Color(0xFF55474E),
    primary: Color(0xFFD5B1DA),
    onPrimary: Color(0xFF3A1F40),
    primaryContainer: Color(0xFF4B3450),
    onPrimaryContainer: Color(0xFFF1DDF4),
    protein: Color(0xFFB3D2B9),
    fat: Color(0xFFEDC09A),
    carbs: Color(0xFFEDB4C0),
    error: Color(0xFFF0ABA0),
    meal1: Color(0xFF4F4025),
    meal2: Color(0xFF374029),
    meal3: Color(0xFF463549),
    meal4: Color(0xFF523529),
    proteinTint: Color(0xFF2E3A2C),
    fatTint: Color(0xFF443020),
    carbsTint: Color(0xFF442C30),
  );

  @override
  AppPalette copyWith() => this;

  /// Palettes are constants of the design, so there is nothing to blend.
  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) =>
      other is AppPalette ? (t < 0.5 ? this : other) : this;
}

/// Corner radii from DESIGN.html.
abstract final class AppRadii {
  static const double input = 18;
  static const double card = 20;
  static const double button = 28;
  static const double iconButton = 24;
  static const double navBar = 32;
}

/// Sizes and spacing from DESIGN.html.
abstract final class AppSpacing {
  static const double screenPadding = 24;
  static const double fieldHeight = 52;
  static const double buttonHeight = 56;
  static const double touchTarget = 48;
  static const double gap = 16;
}

/// Weights of the Nunito variable font the boards use (400, 600, 700, 800).
abstract final class AppWeights {
  static const regular = FontWeight.w400;
  static const semiBold = FontWeight.w600;
  static const bold = FontWeight.w700;
  static const extraBold = FontWeight.w800;
}
