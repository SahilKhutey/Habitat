// Habitat Standardized Components Widget Tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/core/design_system/components/buttons/habitat_buttons.dart';
import 'package:habitat_mobile/core/design_system/components/cards/habitat_card.dart';
import 'package:habitat_mobile/core/design_system/components/feedback/habitat_feedback.dart';
import 'package:habitat_mobile/core/design_system/components/inputs/habitat_inputs.dart';
import 'package:habitat_mobile/core/theme/habitat_theme.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(
      theme: HabitatTheme.darkTheme,
      home: Scaffold(body: child),
    );
  }

  group('Standardized Component Suite Tests', () {
    testWidgets('HabitatPrimaryButton handles tap and loading states', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        wrapWidget(
          HabitatPrimaryButton(
            label: 'Execute Mission',
            onPressed: () => pressed = true,
          ),
        ),
      );

      expect(find.text('Execute Mission'), findsOneWidget);
      await tester.tap(find.text('Execute Mission'));
      expect(pressed, isTrue);

      // Loading state
      await tester.pumpWidget(
        wrapWidget(
          HabitatPrimaryButton(
            label: 'Execute Mission',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('HabitatCard renders child cleanly', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const HabitatCard(
            child: Text('Card Content'),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('HabitatTextField accepts and enters user input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        wrapWidget(
          HabitatTextField(
            controller: controller,
            label: 'Mission Title',
            hint: 'e.g. 50 Pushups',
          ),
        ),
      );

      expect(find.text('Mission Title'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Cold Shower Challenge');
      expect(controller.text, equals('Cold Shower Challenge'));
    });

    testWidgets('HabitatEmptyState displays message and action', (tester) async {
      var actionTriggered = false;

      await tester.pumpWidget(
        wrapWidget(
          HabitatEmptyState(
            icon: Icons.checklist,
            title: 'No Active Tasks',
            message: 'Create your first discipline habit to begin.',
            action: HabitatPrimaryButton(
              label: 'Create Habit',
              onPressed: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('No Active Tasks'), findsOneWidget);
      expect(find.text('Create your first discipline habit to begin.'), findsOneWidget);
      expect(find.text('Create Habit'), findsOneWidget);

      await tester.tap(find.text('Create Habit'));
      expect(actionTriggered, isTrue);
    });
  });
}
