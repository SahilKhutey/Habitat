// Habitat Design Tokens Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/core/design_system/tokens/breakpoints.dart';
import 'package:habitat_mobile/core/design_system/tokens/colors.dart';
import 'package:habitat_mobile/core/design_system/tokens/motion.dart';
import 'package:habitat_mobile/core/design_system/tokens/radii.dart';
import 'package:habitat_mobile/core/design_system/tokens/spacing.dart';
import 'package:habitat_mobile/core/design_system/tokens/typography.dart';

void main() {
  group('Design Tokens Unit Tests', () {
    test('HabitatSpacing follows arithmetic rhythm', () {
      expect(HabitatSpacing.xxs, equals(4.0));
      expect(HabitatSpacing.xs, equals(8.0));
      expect(HabitatSpacing.sm, equals(12.0));
      expect(HabitatSpacing.md, equals(16.0));
      expect(HabitatSpacing.lg, equals(20.0));
      expect(HabitatSpacing.xl, equals(24.0));
      expect(HabitatSpacing.xxl, equals(32.0));
      expect(HabitatSpacing.xxxl, equals(40.0));
      expect(HabitatSpacing.huge, equals(48.0));
      expect(HabitatSpacing.section, equals(56.0));
    });

    test('HabitatRadius provides expected corner tokens', () {
      expect(HabitatRadius.none, equals(0.0));
      expect(HabitatRadius.xs, equals(6.0));
      expect(HabitatRadius.sm, equals(10.0));
      expect(HabitatRadius.md, equals(14.0));
      expect(HabitatRadius.lg, equals(18.0));
      expect(HabitatRadius.xl, equals(24.0));
      expect(HabitatRadius.pill, equals(999.0));
    });

    test('HabitatTypography font styles define consistent hierarchy', () {
      expect(HabitatTypography.fontHeading, equals('Poppins'));
      expect(HabitatTypography.fontBody, equals('Inter'));
      expect(HabitatTypography.display, equals(36.0));
      expect(HabitatTypography.title, equals(22.0));
      expect(HabitatTypography.body, equals(14.0));
      expect(HabitatTypography.caption, equals(10.0));
    });

    test('HabitatColors palette defines obsidian botanical values', () {
      expect(HabitatColors.forest.value, equals(0xFF0F2E1F));
      expect(HabitatColors.growthGreen.value, equals(0xFF4CAF50));
      expect(HabitatColors.backgroundDark.value, equals(0xFF081C13));
      expect(HabitatColors.surfacePrimary.value, equals(0xFF10291E));
    });

    test('HabitatMotion defines fast, standard, and slow durations', () {
      expect(HabitatMotion.fast.inMilliseconds, equals(150));
      expect(HabitatMotion.standard.inMilliseconds, equals(250));
      expect(HabitatMotion.slow.inMilliseconds, equals(400));
    });

    test('HabitatBreakpoints defines mobile, tablet, and desktop bounds', () {
      expect(HabitatBreakpoints.mobile, equals(600.0));
      expect(HabitatBreakpoints.tablet, equals(900.0));
      expect(HabitatBreakpoints.desktop, equals(1200.0));
    });
  });
}
