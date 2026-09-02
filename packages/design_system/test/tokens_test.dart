// Unit Tests for Design Tokens & Themes
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:design_system/design_system.dart';

void main() {
  test('AppColors contains valid semantic colors for light and dark themes', () {
    expect(AppColors.darkBackground, const Color(0xFF0A0A0C));
    expect(AppColors.crimsonAlert, const Color(0xFFFF3B30));
    expect(AppColors.amberFocus, const Color(0xFFFF9500));
    expect(AppColors.emeraldVictory, const Color(0xFF34C759));
  });

  test('AppSpacing follows strict 4pt grid', () {
    expect(AppSpacing.xs, 4.0);
    expect(AppSpacing.sm, 8.0);
    expect(AppSpacing.md, 12.0);
    expect(AppSpacing.lg, 16.0);
    expect(AppSpacing.xl, 24.0);
  });

  test('AppTheme creates valid light and dark ThemeData instances', () {
    final light = AppTheme.light;
    final dark = AppTheme.dark;

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(dark.scaffoldBackgroundColor, AppColors.darkBackground);
  });

  test('public design system token API is complete', () {
    expect(AppRadii.card, equals(18.0));
    expect(AppRadii.button, equals(14.0));
    expect(AppElevation.card, equals(2.0));
    expect(AppElevation.modal, equals(8.0));

    expect(AppDurations.instant, isA<Duration>());
    expect(AppDurations.fast, isA<Duration>());
    expect(AppDurations.standard, isA<Duration>());
    expect(AppDurations.normal, isA<Duration>());
    expect(AppDurations.slow, isA<Duration>());
    expect(AppDurations.instant, equals(const Duration(milliseconds: 0)));
    expect(AppDurations.fast, equals(const Duration(milliseconds: 150)));
    expect(AppDurations.standard, equals(const Duration(milliseconds: 250)));
    expect(AppDurations.normal, equals(AppDurations.standard));
  });
}
