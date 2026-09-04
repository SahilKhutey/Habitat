// Habitat Home Page Widget Tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/core/theme/habitat_theme.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/home/application/home_controller.dart';
import 'package:habitat_mobile/features/home/domain/services/home_service.dart';
import 'package:habitat_mobile/features/home/presentation/pages/home_page.dart';
import 'package:habitat_mobile/features/home/presentation/widgets/current_action_card.dart';
import 'package:habitat_mobile/features/home/presentation/widgets/health_summary.dart';
import 'package:habitat_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:habitat_mobile/features/home/presentation/widgets/progress_summary.dart';
import 'package:habitat_mobile/features/home/presentation/widgets/quick_actions.dart';
import 'package:habitat_mobile/features/home/presentation/widgets/streak_summary.dart';
import 'package:habitat_mobile/features/home/presentation/widgets/today_summary.dart';
import 'package:habitat_mobile/features/home/presentation/widgets/upcoming_tasks.dart';

void main() {
  late LocalDatabase db;
  late HomeService service;
  late HomeController controller;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    service = HomeService(db);
    controller = HomeController(service: service, database: db);
  });

  tearDown(() {
    controller.dispose();
  });

  Widget buildTestWidget({HomeController? testController}) {
    return MaterialApp(
      theme: HabitatTheme.darkTheme,
      home: HomePage(
        controller: testController ?? controller,
      ),
    );
  }

  group('HomePage Widget Tests', () {
    testWidgets('renders all Home foundation sections in order',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(HomeHeader), findsOneWidget);
      expect(find.byType(CurrentActionCard), findsOneWidget);
      expect(find.byType(TodaySummaryCard), findsOneWidget);
      expect(find.byType(UpcomingTasksCard), findsOneWidget);
      expect(find.byType(ProgressSummaryCard), findsOneWidget);
      expect(find.byType(HealthSummaryCard), findsOneWidget);
      expect(find.byType(StreakCard), findsOneWidget);
      expect(find.byType(QuickActionBar), findsOneWidget);
    });

    testWidgets('QuickActionBar taps log water reactively', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final waterButton = find.text('+ 250ml Water');
      expect(waterButton, findsOneWidget);

      await tester.tap(waterButton);
      await tester.pumpAndSettle();

      expect(find.text('💧 250ml water recorded'), findsOneWidget);
      expect(db.getWaterEntriesForDay(DateTime.now()).length, equals(1));
    });

    testWidgets('QuickActionBar taps log meal reactively', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final mealButton = find.text('+ Meal Log');
      expect(mealButton, findsOneWidget);

      await tester.tap(mealButton);
      await tester.pumpAndSettle();

      expect(find.text('🍽 Meal recorded'), findsOneWidget);
      expect(db.getMealEntriesForDay(DateTime.now()).length, equals(1));
    });

    testWidgets('shows empty onboarding state when no tasks exist',
        (tester) async {
      // Clear tasks completely
      db.resetAllData();
      // Remove default templates for this test
      final allTasks = db.getAllTasks();
      for (final t in allTasks) {
        db.saveTask(LocalTask(
          id: t.id,
          title: t.title,
          category: t.category,
          taskType: t.taskType,
          active: false,
          createdAt: t.createdAt,
          updatedAt: t.updatedAt,
        ));
      }

      final emptyController = HomeController(service: service, database: db);
      await tester.pumpWidget(buildTestWidget(testController: emptyController));
      await tester.pumpAndSettle();

      expect(find.text('WELCOME TO HABITAT'), findsOneWidget);
      expect(find.text('Create First Task'), findsOneWidget);

      emptyController.dispose();
    });
  });
}
