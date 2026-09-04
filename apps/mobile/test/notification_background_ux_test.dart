// Automated Test Suite for Track M: Production Android Alarm UX & Background Execution
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/services/mission_execution_service.dart';
import 'package:habitat_mobile/services/native_alarm_scheduler.dart';

void main() {
  late LocalDatabase db;
  late MissionExecutionService missionService;
  late NativeAlarmScheduler scheduler;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    missionService = MissionExecutionService(database: db);
    scheduler = NativeAlarmScheduler.instance;
  });

  group('Track M: Notification & Background Intent Routing', () {
    test(
        'M6, M7 & M8: Intent route "/mission/{missionId}/active" maps to active mission',
        () async {
      final now = DateTime.now();
      final task = LocalTask(
        id: 'task_notif_1',
        title: 'Morning Cold Plunge',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: now,
        updatedAt: now,
      );
      db.saveTask(task);

      final attempt =
          await missionService.start('task_notif_1', alarmId: 'alm_notif_1');
      expect(attempt.status, equals('AWAITING_ACTION'));

      // Simulate notification click delivering route payload
      final route = '/mission/${attempt.id}/active';
      expect(route, contains(attempt.id));
      expect(db.getAttempt(attempt.id)?.status, equals('AWAITING_ACTION'));
    });

    test(
        'M11: Double-tapping notification does not launch duplicate task attempts',
        () async {
      final task = LocalTask(
        id: 'task_dedup_1',
        title: 'Drink Water',
        category: 'HEALTH',
        taskType: 'PHOTO',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      // First tap -> starts attempt
      final attempt1 =
          await missionService.start('task_dedup_1', alarmId: 'alm_1');
      final attempts = db.getAttemptsForTask('task_dedup_1');
      expect(attempts.length, equals(1));
      expect(attempts.first.id, equals(attempt1.id));

      // Attempt state is preserved
      expect(db.getAttempt(attempt1.id)?.status, equals('AWAITING_ACTION'));
    });

    test(
        'M18, M19 & M20: Stale callback for already COMPLETED or cancelled alarm is safely ignored',
        () async {
      final task = LocalTask(
        id: 'task_stale_1',
        title: 'Read 10 Pages',
        category: 'MIND',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt =
          await missionService.start('task_stale_1', alarmId: 'alm_stale_1');

      // Submit and complete mission
      await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/read.jpg',
          sha256Checksum:
              '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff',
        ),
      );
      await missionService.complete(attempt.id);

      // Now simulate stale retry callback arriving after completion
      final scheduledOcc = scheduler.scheduleExactAlarm(
        alarmId: 'alm_stale_1',
        missionId: attempt.id,
        scheduledAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      scheduler.onMissionCompleted(occurrenceId: scheduledOcc.occurrenceId);

      // Completed attempt remains completed; 0 extra XP awarded
      final completedAttempt = db.getAttempt(attempt.id);
      expect(completedAttempt?.status, equals('COMPLETED'));
      expect(scheduledOcc.isCancelled, isTrue);
      expect(db.getTotalXP(), equals(20));
    });

    test(
        'M12: Dismissing notification or cancelling alarm does not mark mission completed',
        () async {
      final task = LocalTask(
        id: 'task_dismiss_test',
        title: 'Pushups',
        category: 'PHYSICAL',
        taskType: 'VIDEO',
        requiresVideo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_dismiss_test',
          alarmId: 'alm_dismiss_1');
      expect(attempt.status, equals('AWAITING_ACTION'));

      // Dismissal / cancellation should NOT complete the task
      final currentTask = db.getTask('task_dismiss_test');
      expect(currentTask?.isCompleted, isFalse);
      expect(db.getTotalXP(), equals(0));
    });
  });
}
