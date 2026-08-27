// Unit Tests for Design Tokens & Themes
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/design_system.dart';

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
}
