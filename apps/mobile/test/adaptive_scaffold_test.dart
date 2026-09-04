// Habitat Adaptive Scaffold Widget Tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/core/design_system/responsive/adaptive_scaffold.dart';
import 'package:habitat_mobile/core/theme/habitat_theme.dart';

void main() {
  group('HabitatAdaptiveScaffold Widget Tests', () {
    testWidgets(
        'renders Bottom NavigationBar on mobile screens (< 700px width)',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var selected = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: HabitatTheme.darkTheme,
          home: HabitatAdaptiveScaffold(
            selectedIndex: selected,
            onDestinationSelected: (idx) => selected = idx,
            child: const Text('Mobile Content View'),
          ),
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Mobile Content View'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets(
        'renders NavigationRail on tablet/desktop screens (>= 700px width)',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var selected = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: HabitatTheme.darkTheme,
          home: HabitatAdaptiveScaffold(
            selectedIndex: selected,
            onDestinationSelected: (idx) => selected = idx,
            child: const Text('Desktop Content View'),
          ),
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Desktop Content View'), findsOneWidget);
    });
  });
}
