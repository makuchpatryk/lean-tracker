import 'package:flutter/material.dart';

import 'tokens.dart';

const _fontFamily = 'Nunito';

/// Light theme from the DESIGN.html `.light` tokens.
ThemeData lightTheme() => _theme(AppPalette.light, Brightness.light);

/// Dark theme from the DESIGN.html `.dark` tokens.
ThemeData darkTheme() => _theme(AppPalette.dark, Brightness.dark);

/// The palette of the current theme. Falls back to light only if a test builds a bare theme.
extension AppPaletteOnContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

ThemeData _theme(AppPalette p, Brightness brightness) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    primaryContainer: p.primaryContainer,
    onPrimaryContainer: p.onPrimaryContainer,
    secondary: p.primary,
    onSecondary: p.onPrimary,
    secondaryContainer: p.primaryContainer,
    onSecondaryContainer: p.onPrimaryContainer,
    error: p.error,
    onError: p.background,
    surface: p.surface,
    onSurface: p.ink,
    onSurfaceVariant: p.muted,
    surfaceContainerHighest: p.surfaceVariant,
    outline: p.line,
    outlineVariant: p.line,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: _fontFamily,
  );
  return base.copyWith(
    scaffoldBackgroundColor: p.background,
    textTheme: _withWeightAxis(
      base.textTheme.apply(bodyColor: p.ink, displayColor: p.ink),
    ),
    // Bottom bar of the DESIGN boards: a surface pill, the selected destination filled with primary.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.primary,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? p.onPrimary : p.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => nunito(
          13,
          AppWeights.extraBold,
          color: states.contains(WidgetState.selected) ? p.primary : p.muted,
        ),
      ),
    ),
    extensions: [p],
  );
}

/// Nunito ships as one variable font, so each style also sets the `wght` axis from its weight.
TextTheme _withWeightAxis(TextTheme t) {
  TextStyle? axis(TextStyle? s) {
    if (s == null) return null;
    final weight = (s.fontWeight ?? FontWeight.w400).value.toDouble();
    return s.copyWith(fontVariations: [FontVariation('wght', weight)]);
  }

  return t.copyWith(
    displayLarge: axis(t.displayLarge),
    displayMedium: axis(t.displayMedium),
    displaySmall: axis(t.displaySmall),
    headlineLarge: axis(t.headlineLarge),
    headlineMedium: axis(t.headlineMedium),
    headlineSmall: axis(t.headlineSmall),
    titleLarge: axis(t.titleLarge),
    titleMedium: axis(t.titleMedium),
    titleSmall: axis(t.titleSmall),
    bodyLarge: axis(t.bodyLarge),
    bodyMedium: axis(t.bodyMedium),
    bodySmall: axis(t.bodySmall),
    labelLarge: axis(t.labelLarge),
    labelMedium: axis(t.labelMedium),
    labelSmall: axis(t.labelSmall),
  );
}

/// Text style for [weight] with the variable-font axis set; use it for any style built by hand.
TextStyle nunito(double size, FontWeight weight, {Color? color}) => TextStyle(
  fontFamily: _fontFamily,
  fontSize: size,
  fontWeight: weight,
  fontVariations: [FontVariation('wght', weight.value.toDouble())],
  color: color,
);
