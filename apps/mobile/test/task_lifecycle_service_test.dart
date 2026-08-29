// Habitat Task Lifecycle & Action Execution Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/tasks/domain/models/habitat_action.dart';
import 'package:habitat_mobile/features/tasks/domain/repositories/task_repository.dart';
import 'package:habitat_mobile/features/tasks/domain/services/action_executor.dart';
import 'package:habitat_mobile/features/tasks/domain/services/task_lifecycle_service.dart';

void main() {
  late LocalDatabase db;
  late TaskRepository taskRepo;
  late TaskLifecycleService lifecycleService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    taskRepo = TaskRepository(db);
    lifecycleService = TaskLifecycleService(
      taskRepository: taskRepo,
      database: db,
      actionExecutor: ActionExecutor(),
    );
  });

  group('TaskLifecycleService Integration Tests', () {
    test('createTask() persists task in database', () {
      final task = LocalTask(
        id: 'task_001',
        title: 'Morning 50 Pushups',
        category: 'PHYSICAL',
        taskType: 'PHOTO',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      lifecycleService.createTask(task);

      final retrieved = lifecycleService.getTaskById('task_001');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Morning 50 Pushups'));
      expect(retrieved.isCompleted, isFalse);
    });

    test('completeTaskWithAction() verifies checklist action and completes task', () async {
      final task = LocalTask(
        id: 'task_002',
        title: 'Morning Routine Checklist',
        category: 'HABIT',
        taskType: 'CHECKLIST',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      lifecycleService.createTask(task);

      const action = HabitatAction(
        id: 'act_001',
        taskId: 'task_002',
        type: ActionType.checklist,
        configuration: {'totalItems': 2},
      );

      // Incomplete payload fails verification
      final fail = await lifecycleService.completeTaskWithAction(
        'task_002',
        action: action,
        actionPayload: {'checkedItems': ['Item 1']},
      );
      expect(fail, isFalse);
      expect(lifecycleService.getTaskById('task_002')!.isCompleted, isFalse);

      // Complete payload succeeds verification
      final success = await lifecycleService.completeTaskWithAction(
        'task_002',
        action: action,
        actionPayload: {'checkedItems': ['Item 1', 'Item 2']},
      );
      expect(success, isTrue);
      expect(lifecycleService.getTaskById('task_002')!.isCompleted, isTrue);
    });

    test('reopenTask() un-completes task cleanly', () async {
      final task = LocalTask(
        id: 'task_003',
        title: 'Drink 500ml Water',
        category: 'HEALTH',
        taskType: 'CHECKLIST',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      lifecycleService.createTask(task);
      await lifecycleService.completeTaskWithAction('task_003');
      expect(lifecycleService.getTaskById('task_003')!.isCompleted, isTrue);

      lifecycleService.reopenTask('task_003');
      expect(lifecycleService.getTaskById('task_003')!.isCompleted, isFalse);
    });
  });
}
