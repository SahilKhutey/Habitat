// Habitat Theme Extension Unit Tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/core/design_system/theme/habitat_theme_extension.dart';

void main() {
  group('HabitatThemeExtension Unit Tests', () {
    test('Dark and Light presets have valid initial colors', () {
      const dark = HabitatThemeExtension.dark;
      const light = HabitatThemeExtension.light;

      expect(dark.success, isNotNull);
      expect(dark.warning, isNotNull);
      expect(dark.danger, isNotNull);
      expect(dark.cardRadius, equals(18.0));

      expect(light.success, isNotNull);
      expect(light.warning, isNotNull);
      expect(light.danger, isNotNull);
    });

    test('copyWith() returns new instance with updated properties', () {
      const original = HabitatThemeExtension.dark;
      final updated =
          original.copyWith(cardRadius: 24.0, warning: Colors.amber);

      expect(updated.cardRadius, equals(24.0));
      expect(updated.warning, equals(Colors.amber));
      expect(updated.success, equals(original.success));
    });

    test('lerp() interpolates between two extensions', () {
      const a = HabitatThemeExtension.dark;
      const b = HabitatThemeExtension.light;

      final mid = a.lerp(b, 0.5);
      expect(mid, isNotNull);
      expect(mid.cardRadius, equals(18.0));
    });
  });
}
