import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/ui/theme.dart';
import 'package:lean_tracker/ui/tokens.dart';

/// WCAG 2.x contrast ratio.
double contrast(Color a, Color b) {
  double luminance(Color c) {
    double channel(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(c.r) +
        0.7152 * channel(c.g) +
        0.0722 * channel(c.b);
  }

  final la = luminance(a);
  final lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  final themes = {'light': lightTheme(), 'dark': darkTheme()};

  for (final entry in themes.entries) {
    group('${entry.key} theme', () {
      final theme = entry.value;

      test('uses Material 3 and Nunito (FR-017, DESIGN)', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.textTheme.bodyMedium?.fontFamily, 'Nunito');
        expect(theme.textTheme.titleLarge?.fontFamily, 'Nunito');
      });

      test('carries the palette for its brightness', () {
        final palette = theme.extension<AppPalette>();
        expect(
          palette,
          entry.key == 'light' ? AppPalette.light : AppPalette.dark,
        );
        expect(
          theme.brightness,
          entry.key == 'light' ? Brightness.light : Brightness.dark,
        );
      });

      test('text and surface pairs reach contrast 4.5:1 (§16)', () {
        final p = theme.extension<AppPalette>()!;
        final pairs = <String, (Color, Color)>{
          'ink on background': (p.ink, p.background),
          'ink on surface': (p.ink, p.surface),
          'muted on background': (p.muted, p.background),
          'muted on surface': (p.muted, p.surface),
          'primary on background': (p.primary, p.background),
          'primary on surface': (p.primary, p.surface),
          'onPrimary on primary': (p.onPrimary, p.primary),
          'onPrimaryContainer on primaryContainer': (
            p.onPrimaryContainer,
            p.primaryContainer,
          ),
          'error on background': (p.error, p.background),
          'error on surface': (p.error, p.surface),
        };
        for (final pair in pairs.entries) {
          expect(
            contrast(pair.value.$1, pair.value.$2),
            greaterThanOrEqualTo(4.5),
            reason: pair.key,
          );
        }
      });
    });
  }
}
