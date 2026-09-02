// Widget Tests for Design System Components
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:design_system/design_system.dart';

void main() {
  testWidgets('AppButton renders label and handles tap callback', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: AppButton.primary(
            label: 'Start Mission',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Start Mission'), findsOneWidget);
    await tester.tap(find.text('Start Mission'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('AppCard renders child content inside border container', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: AppCard(
            child: Text('Card Content Test'),
          ),
        ),
      ),
    );

    expect(find.text('Card Content Test'), findsOneWidget);
  });
}
