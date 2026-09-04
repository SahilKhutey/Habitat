// Habitat Web Command Center & Analytics Dashboard Widget Tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_web/main.dart';

void main() {
  testWidgets(
      'Web Command Center renders title, sidebar navigation, and metrics overview',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const HabitatWebCommandApp());
    await tester.pumpAndSettle();

    // Verify Brand / Header
    expect(find.text('HABITAT'), findsOneWidget);
    expect(find.text('Command Overview'), findsOneWidget);

    // Verify Navigation Tiles
    expect(find.text('Mission Protocols'), findsOneWidget);
    expect(find.text('Resistance Analytics'), findsOneWidget);
    expect(find.text('XP Audit Ledger'), findsOneWidget);
    expect(find.text('Task Catalog'), findsOneWidget);
  });
}
