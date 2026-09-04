// Automated Test Suite for Phase Y: Controlled 1.0 Release, Go-Live & Production Rollout
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/tasks/domain/services/alarm_service.dart';
import 'package:habitat_mobile/services/mission_execution_service.dart';
import 'package:habitat_mobile/services/native_alarm_scheduler.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalDatabase db;
  late MissionExecutionService missionService;
  late AlarmService alarmService;
  late NativeAlarmScheduler scheduler;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    db = LocalDatabase.instance;
    db.resetAllData(populateDefaultTemplates: false);
    missionService = MissionExecutionService(database: db);
    alarmService = AlarmService(db);
    scheduler = NativeAlarmScheduler.instance;
  });

  group('Phase Y: 1.0 Go-Live Heartbeat & Production Verification (Y10, Y27)',
      () {
    test(
        'Y10 & Y27: Executes 1.0 Heartbeat Path with complete referential & reward integrity',
        () async {
      // 1. Task & Alarm Creation
      final task = LocalTask(
        id: 'task_phase_y_golive',
        title: 'Morning Pushup Protocol',
        category: 'PHYSICAL',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final alarm = LocalAlarm(
        id: 'alm_phase_y_golive',
        taskId: 'task_phase_y_golive',
        scheduledTime: '06:00',
        enabled: true,
        createdAt: DateTime.now(),
      );
      db.saveAlarm(alarm);

      // 2. Alarm Trigger & Mission Launch
      final occurrence = scheduler.scheduleExactAlarm(
        alarmId: 'alm_phase_y_golive',
        missionId: 'task_phase_y_golive',
        scheduledAt: DateTime.now(),
      );
      expect(occurrence.isDisarmed, isFalse);

      final attempt = await missionService.start('task_phase_y_golive',
          alarmId: 'alm_phase_y_golive');
      expect(attempt.status, equals('AWAITING_ACTION'));

      // 3. Proof Capture & SHA-256 Validation
      const proofPayload = ProofSubmission(
        type: 'PHOTO',
        filePath: 'habitat_storage://proofs/golive_photo.jpg',
        sha256Checksum:
            '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff',
      );

      final proofResult =
          await missionService.submitProof(attempt.id, proofPayload);
      expect(proofResult.isPassed, isTrue);

      // 4. Atomic Completion
      final completionResult = await missionService.complete(attempt.id);
      expect(completionResult.isSuccess, isTrue);
      expect(completionResult.earnedXp, equals(20));
      expect(completionResult.currentStreak, equals(1));

      // 5. Disarm Alarm & Cancel Retries
      scheduler.onMissionCompleted(occurrenceId: occurrence.occurrenceId);
      expect(occurrence.isCancelled, isTrue);

      // 6. Persistence & Reload
      await db.flush();
      final stateSnapshot = db.exportCompleteStateJson();

      db.resetAllData(populateDefaultTemplates: false);
      expect(db.getAllTasks().isEmpty, isTrue);

      db.restoreFromStateJson(stateSnapshot);

      expect(db.getTask('task_phase_y_golive')?.isCompleted, isTrue);
      expect(db.getTotalXP(), equals(20));
      expect(db.getStreak().currentStreak, equals(1));
    });
  });

  group('Phase Y: Rollback & Hotfix Idempotency Invariants (Y20, Y24)', () {
    test(
        'Y20 & Y24: Hotfix recovery preserves existing reward ledger and prevents duplicate increments',
        () async {
      final task = LocalTask(
        id: 'task_hotfix_audit',
        title: 'Daily Meditation',
        category: 'MIND',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_hotfix_audit');
      await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/meditation.jpg',
          sha256Checksum:
              'abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef1234',
        ),
      );

      final res1 = await missionService.complete(attempt.id);
      expect(res1.isSuccess, isTrue);
      expect(res1.earnedXp, equals(20));
      expect(db.getTotalXP(), equals(20));

      // Re-invoking complete in hotfix patched state is safe & idempotent
      final res2 = await missionService.complete(attempt.id);
      expect(res2.isSuccess, isTrue);
      expect(res2.earnedXp, equals(0)); // 0 duplicate XP
      expect(db.getTotalXP(), equals(20));
      expect(db.getStreak().currentStreak, equals(1));
    });
  });
}
