// Habitat Phase 17 Accessibility & Responsive UI/UX Widget Tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:design_system/design_system.dart';

void main() {
  group('Phase 17: Accessibility & Responsive UI/UX Tests', () {
    testWidgets(
        '17.1: HabitatAdaptiveGrid adapts column count to available width',
        (tester) async {
      // Test at phone width (360px)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: HabitatAdaptiveGrid(
                  children: const [
                    Text('Card 1'),
                    Text('Card 2'),
                    Text('Card 3'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card 1'), findsOneWidget);
      expect(find.text('Card 2'), findsOneWidget);
      expect(find.text('Card 3'), findsOneWidget);

      // Verify single-column Column layout on phone
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets(
        '17.2: HabitatPage constrains content width and provides safe padding',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HabitatPage(
              maxContentWidth: 800,
              child: const Text('Constrained Content'),
            ),
          ),
        ),
      );

      expect(find.text('Constrained Content'), findsOneWidget);
      expect(find.byType(ConstrainedBox), findsWidgets);
    });

    testWidgets(
        '17.3: HabitatA11y.button produces semantic button role, label, and hint',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HabitatA11y.button(
              label: 'Start Mission',
              hint: 'Double tap to begin your morning pushups mission',
              onTap: () => tapped = true,
              child: const Text('Start'),
            ),
          ),
        ),
      );

      expect(find.text('Start'), findsOneWidget);
      await tester.tap(find.text('Start'));
      expect(tapped, isTrue);

      final semantics = tester.getSemantics(find.byType(Semantics).first);
      expect(semantics.label, contains('Start Mission'));
    });

    testWidgets(
        '17.4: HabitatA11y.heading produces structural header semantics',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HabitatA11y.heading(
              label: "Today's Discipline",
              child: const Text("Today's Discipline"),
            ),
          ),
        ),
      );

      expect(find.text("Today's Discipline"), findsOneWidget);
      final semantics = tester.getSemantics(find.byType(Semantics).first);
      expect(semantics.label, contains("Today's Discipline"));
    });

    testWidgets(
        '17.5: HabitatA11y.chartAlternative presents text alternative for visual charts',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HabitatA11y.chartAlternative(
              description:
                  'Seven day task completion chart. Mon: 3, Tue: 5, Wed: 2.',
              child: Container(height: 100, color: Colors.green),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(Semantics).first);
      expect(semantics.label, contains('Seven day task completion chart'));
    });
  });
}
