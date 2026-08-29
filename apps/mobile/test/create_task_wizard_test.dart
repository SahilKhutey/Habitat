// Habitat 7-Step Create Task Wizard Controller Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/tasks/application/create_task_controller.dart';
import 'package:habitat_mobile/features/tasks/domain/models/action_model.dart';
import 'package:habitat_mobile/features/tasks/domain/models/alarm_model.dart';
import 'package:habitat_mobile/features/tasks/domain/models/schedule_model.dart';
import 'package:habitat_mobile/features/tasks/domain/models/task_model.dart';
import 'package:habitat_mobile/features/tasks/domain/services/task_service.dart';

void main() {
  late LocalDatabase db;
  late TaskService taskService;
  late CreateTaskController controller;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    taskService = TaskService(db);
    controller = CreateTaskController(taskService: taskService);
  });

  tearDown(() {
    controller.dispose();
  });

  group('CreateTaskController Unit Tests', () {
    test('step progression advances and steps backward correctly', () {
      expect(controller.currentStep, equals(0));

      controller.nextStep();
      expect(controller.currentStep, equals(1));

      controller.nextStep();
      expect(controller.currentStep, equals(2));

      controller.previousStep();
      expect(controller.currentStep, equals(1));
    });

    test('updating fields and calling saveTask() persists task cleanly', () {
      controller.updateBasicInfo(
        newTitle: 'Evening Digital Sunset',
        newDescription: 'Turn off all blue light screens 1 hour before bed.',
        newCategory: TaskCategory.routine,
        newDifficulty: TaskDifficulty.hard,
      );

      controller.updateSchedule(
        newRecurrence: ScheduleRecurrenceType.daily,
        newTime: '21:30',
        newDays: [1, 2, 3, 4, 5, 6, 7],
      );

      controller.updateActionAndVerification(
        newActionType: ActionType.photo,
        newInstruction: 'Take a photo of powered down workspace.',
      );

      controller.updateAlarm(
        enabled: true,
        volume: 85,
        mode: DisciplineMode.hardcore,
      );

      controller.updateRetryRules(
        enabled: true,
        intervalMinutes: 5,
        maxRetries: 3,
      );

      expect(controller.calculatedXp, equals(50));

      final created = controller.saveTask();

      expect(created.id, startsWith('task-'));
      expect(created.title, equals('Evening Digital Sunset'));
      expect(created.schedule.timeOfDay, equals('21:30'));
      expect(created.alarm, isNotNull);
      expect(created.alarm!.timeOfDay, equals('21:30'));

      final retrieved = taskService.getTaskById(created.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Evening Digital Sunset'));
    });
  });
}
