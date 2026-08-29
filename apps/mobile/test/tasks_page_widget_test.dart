// Habitat Tasks Page Widget Tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/core/theme/habitat_theme.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/tasks/application/task_controller.dart';
import 'package:habitat_mobile/features/tasks/domain/services/task_service.dart';
import 'package:habitat_mobile/features/tasks/presentation/pages/tasks_page.dart';
import 'package:habitat_mobile/features/tasks/presentation/widgets/task_card.dart';

void main() {
  late LocalDatabase db;
  late TaskService taskService;
  late TaskController controller;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    taskService = TaskService(db);
    controller = TaskController(taskService: taskService, database: db);
  });

  tearDown(() {
    controller.dispose();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      theme: HabitatTheme.darkTheme,
      home: TasksPage(controller: controller),
    );
  }

  group('TasksPage Widget Tests', () {
    testWidgets('renders filter chips, task cards, and create task CTA', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('DISCIPLINE TASKS'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('SCHEDULED'), findsOneWidget);
      expect(find.text('CREATE TASK'), findsOneWidget);
      expect(find.byType(TaskCard), findsWidgets);
    });

    testWidgets('switching filter updates active filter selection', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final activeFilterChip = find.text('ACTIVE');
      expect(activeFilterChip, findsOneWidget);

      await tester.tap(activeFilterChip);
      await tester.pumpAndSettle();

      expect(controller.activeFilter, equals('ACTIVE'));
    });
  });
}
