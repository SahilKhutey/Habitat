// Habitat Home Service Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/home/domain/models/home_state_model.dart';
import 'package:habitat_mobile/features/home/domain/services/home_service.dart';

void main() {
  late LocalDatabase db;
  late HomeService service;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    service = HomeService(db);
  });

  group('HomeService Unit Tests', () {
    test('load() returns valid initial HomeStateModel with template tasks', () {
      final state = service.load(now: DateTime(2026, 8, 29, 8, 0));

      expect(state.user.displayName, isNotEmpty);
      expect(state.user.greeting, equals('Good morning'));
      expect(state.currentAction, isNotNull);
      expect(state.currentAction!.status, equals(CurrentActionStatus.ready));
      expect(state.dailyProgress.totalTasks, greaterThan(0));
      expect(state.dailyProgress.completedTasks, equals(0));
      expect(state.dailyProgress.completionPercentage, equals(0.0));
      expect(state.health.waterMilliliters, equals(0));
      expect(state.streak.currentStreak, equals(0));
      expect(state.streak.stageMotto, equals('Sprout Stage'));
    });

    test('CurrentAction resolves to active when attempt is in progress', () {
      final tasks = db.getAllTasks();
      expect(tasks, isNotEmpty);

      final taskId = tasks.first.id;
      db.recordAttempt(LocalTaskAttempt(
        id: 'attempt-001',
        taskId: taskId,
        alarmId: 'alarm-001',
        attemptNumber: 1,
        status: 'AWAITING_ACTION',
        triggeredAt: DateTime(2026, 8, 29, 7, 0),
      ));

      final state = service.load(now: DateTime(2026, 8, 29, 7, 5));

      expect(state.currentAction, isNotNull);
      expect(state.currentAction!.taskId, equals(taskId));
      expect(state.currentAction!.status, equals(CurrentActionStatus.active));
      expect(state.currentAction!.isActionable, isTrue);
      expect(state.currentAction!.ctaLabel, equals('Continue Action'));
    });

    test('CurrentAction resolves to retryRequired when verification fails with RETRY', () {
      final tasks = db.getAllTasks();
      final taskId = tasks.first.id;

      db.recordAttempt(LocalTaskAttempt(
        id: 'attempt-002',
        taskId: taskId,
        alarmId: 'alarm-002',
        attemptNumber: 1,
        status: 'RETRY',
        triggeredAt: DateTime(2026, 8, 29, 7, 0),
      ));

      final state = service.load(now: DateTime(2026, 8, 29, 7, 10));

      expect(state.currentAction, isNotNull);
      expect(state.currentAction!.status, equals(CurrentActionStatus.retryRequired));
      expect(state.currentAction!.isActionable, isTrue);
      expect(state.currentAction!.ctaLabel, equals('Retry Verification'));
    });

    test('CurrentAction resolves to completed when all tasks for today are done', () {
      final tasks = db.getAllTasks();
      final now = DateTime(2026, 8, 29, 12, 0);

      for (var i = 0; i < tasks.length; i++) {
        db.recordAttempt(LocalTaskAttempt(
          id: 'attempt-done-$i',
          taskId: tasks[i].id,
          alarmId: 'alarm-$i',
          attemptNumber: 1,
          status: 'COMPLETED',
          triggeredAt: now,
          completedAt: now,
        ));
      }

      final state = service.load(now: now);

      expect(state.currentAction, isNotNull);
      expect(state.currentAction!.status, equals(CurrentActionStatus.completed));
      expect(state.dailyProgress.completedTasks, equals(tasks.length));
      expect(state.dailyProgress.completionPercentage, equals(1.0));
      expect(state.dailyProgress.remainingTasks, equals(0));
    });

    test('Health summary correctly aggregates water, meals, and naps', () {
      final now = DateTime(2026, 8, 29, 14, 0);

      db.addWater(milliliters: 500, recordedAt: now);
      db.addWater(milliliters: 250, recordedAt: now);
      db.addMeal(type: 'breakfast', recordedAt: now);
      db.addMeal(type: 'lunch', recordedAt: now);
      final nap = db.startNap(startedAt: now.subtract(const Duration(minutes: 30)));

      final state = service.load(now: now);

      expect(state.health.waterMilliliters, equals(750));
      expect(state.health.waterPercentage, equals(750 / 2000));
      expect(state.health.mealsLogged, equals(2));
      expect(state.health.mealsPercentage, equals(2 / 4));
      expect(state.health.napRunning, isTrue);

      db.stopNap(endedAt: now);
      final stoppedState = service.load(now: now);
      expect(stoppedState.health.napRunning, isFalse);
      expect(stoppedState.health.napMinutes, equals(30));
    });

    test('Streak summary resolves stage motto correctly', () {
      final state0 = service.load();
      expect(state0.streak.stageMotto, equals('Sprout Stage'));
    });
  });
}
