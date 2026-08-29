// Habitat Task Service Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/tasks/domain/models/action_model.dart';
import 'package:habitat_mobile/features/tasks/domain/models/alarm_model.dart';
import 'package:habitat_mobile/features/tasks/domain/models/retry_rules_model.dart';
import 'package:habitat_mobile/features/tasks/domain/models/schedule_model.dart';
import 'package:habitat_mobile/features/tasks/domain/models/task_model.dart';
import 'package:habitat_mobile/features/tasks/domain/services/task_service.dart';

void main() {
  late LocalDatabase db;
  late TaskService taskService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    taskService = TaskService(db);
  });

  group('TaskService Unit Tests', () {
    test('getAllTasks() loads all template tasks', () {
      final tasks = taskService.getAllTasks();
      expect(tasks, isNotEmpty);
      expect(tasks.length, greaterThanOrEqualTo(8));
      expect(tasks.first.title, isNotEmpty);
      expect(tasks.first.schedule.timeOfDay, isNotEmpty);
    });

    test('getTasksByFilter() filters by ACTIVE, SCHEDULED, PAUSED, ARCHIVED', () {
      final all = taskService.getAllTasks();
      expect(all, isNotEmpty);

      final active = taskService.getTasksByFilter('ACTIVE');
      expect(active.length, equals(all.length));

      taskService.pauseTask(all.first.id);
      final afterPauseActive = taskService.getTasksByFilter('ACTIVE');
      final afterPausePaused = taskService.getTasksByFilter('PAUSED');
      expect(afterPauseActive.length, equals(all.length - 1));
      expect(afterPausePaused.length, equals(1));

      taskService.archiveTask(all[1].id);
      final afterArchive = taskService.getTasksByFilter('ARCHIVED');
      expect(afterArchive.length, equals(1));
    });

    test('saveTask() creates and persists new TaskModel', () {
      final now = DateTime.now();
      final newTask = TaskModel(
        id: 'test-task-101',
        title: 'Cold Shower Discipline',
        description: 'Take a 2-minute freezing cold shower upon waking.',
        category: TaskCategory.physical,
        difficulty: TaskDifficulty.hard,
        status: TaskStatus.ready,
        baseXp: 50,
        schedule: const TaskScheduleModel(timeOfDay: '06:00'),
        action: const TaskActionModel(
          id: 'action-test-101',
          type: ActionType.photo,
          title: 'Cold Shower',
          instruction: 'Take a photo after cold shower.',
          verificationType: VerificationType.photoProof,
        ),
        alarm: const TaskAlarmModel(
          id: 'alarm-test-101',
          taskId: 'test-task-101',
          timeOfDay: '06:00',
        ),
        retryRules: const TaskRetryRulesModel(),
        createdAt: now,
        updatedAt: now,
      );

      taskService.saveTask(newTask);

      final retrieved = taskService.getTaskById('test-task-101');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Cold Shower Discipline'));
      expect(retrieved.baseXp, equals(30)); // Local mapped baseXp
      expect(retrieved.alarm, isNotNull);
      expect(retrieved.alarm!.timeOfDay, equals('06:00'));
    });
  });
}
