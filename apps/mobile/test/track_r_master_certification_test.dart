// Master Acceptance & System Certification Suite for Track R
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/tasks/domain/services/alarm_service.dart';
import 'package:habitat_mobile/services/mission_execution_service.dart';
import 'package:habitat_mobile/services/native_alarm_scheduler.dart';

void main() {
  late LocalDatabase db;
  late MissionExecutionService missionService;
  late AlarmService alarmService;
  late NativeAlarmScheduler scheduler;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    missionService = MissionExecutionService(database: db);
    alarmService = AlarmService(db);
    scheduler = NativeAlarmScheduler.instance;
  });

  group('Track R: Master Golden Path Certification Gate', () {
    test('R1: End-to-End Golden Path Execution with Durability, Idempotency & Alarm Life-Cycle', () async {
      // ───────────────────────────────────────────────────────────────────────
      // 1. BOOTSTRAP & TASK INITIALIZATION
      // ───────────────────────────────────────────────────────────────────────
      final user = db.getOrCreateProfile(name: 'Commander Alpha');
      expect(user.displayName, equals('Commander Alpha'));

      final task = LocalTask(
        id: 'task_golden_path',
        title: 'Morning Sun Salutation & Pushups',
        category: 'PHYSICAL',
        taskType: 'VIDEO',
        requiresVideo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final alarm = LocalAlarm(
        id: 'alm_golden_path',
        taskId: 'task_golden_path',
        scheduledTime: '06:00',
        enabled: true,
        createdAt: DateTime.now(),
      );
      db.saveAlarm(alarm);

      expect(db.getAllTasks().length, equals(1));
      expect(db.getAllAlarms().length, equals(1));

      // ───────────────────────────────────────────────────────────────────────
      // 2. STARTUP ALARM RECONCILIATION
      // ───────────────────────────────────────────────────────────────────────
      final reconciledCount = await alarmService.reconcilePersistedAlarmsOnStartup();
      expect(reconciledCount, equals(1));

      // ───────────────────────────────────────────────────────────────────────
      // 3. OS ALARM TRIGGER & MISSION START
      // ───────────────────────────────────────────────────────────────────────
      final occurrence = scheduler.scheduleExactAlarm(
        alarmId: 'alm_golden_path',
        missionId: 'task_golden_path',
        scheduledAt: DateTime.now(),
      );
      expect(occurrence.isDisarmed, isFalse);

      final attempt = await missionService.start('task_golden_path', alarmId: 'alm_golden_path');
      expect(attempt.status, equals('AWAITING_ACTION'));

      // ───────────────────────────────────────────────────────────────────────
      // 4. PROOF SUBMISSION & VERIFICATION (SHA-256 CHECKED)
      // ───────────────────────────────────────────────────────────────────────
      final proofSubmission = const ProofSubmission(
        type: 'VIDEO',
        filePath: 'habitat_storage://proofs/golden_pushups.mp4',
        sha256Checksum: '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff',
        durationSeconds: 12,
      );

      final verificationResult = await missionService.submitProof(attempt.id, proofSubmission);
      expect(verificationResult.isPassed, isTrue);

      final verifiedAttempt = db.getAttempt(attempt.id);
      expect(verifiedAttempt?.status, equals('PROOF_VERIFIED'));

      // ───────────────────────────────────────────────────────────────────────
      // 5. ATOMIC COMPLETION & RETRY DISARMING
      // ───────────────────────────────────────────────────────────────────────
      final completion = await missionService.complete(attempt.id);
      expect(completion.isSuccess, isTrue);
      expect(completion.earnedXp, equals(20));
      expect(completion.currentStreak, greaterThanOrEqualTo(1));

      scheduler.onMissionCompleted(occurrenceId: occurrence.occurrenceId);
      expect(occurrence.isCancelled, isTrue);

      final completedTask = db.getTask('task_golden_path');
      expect(completedTask?.isCompleted, isTrue);
      expect(db.getTotalXP(), equals(20));

      // ───────────────────────────────────────────────────────────────────────
      // 6. IDEMPOTENCY CONFIRMATION (NO DUPLICATE XP / STREAK)
      // ───────────────────────────────────────────────────────────────────────
      final duplicateCompletion = await missionService.complete(attempt.id);
      expect(duplicateCompletion.isSuccess, isTrue);
      expect(duplicateCompletion.earnedXp, equals(0));
      expect(db.getTotalXP(), equals(20));

      // ───────────────────────────────────────────────────────────────────────
      // 7. DURABLE PERSISTENCE & COLD RESTART RECOVERY
      // ───────────────────────────────────────────────────────────────────────
      final serializedDiskPayload = db.exportCompleteStateJson();
      db.resetAllData();
      expect(db.getAllTasks().isEmpty, isTrue);

      // Hydrate from cold persistence
      db.restoreFromStateJson(serializedDiskPayload);

      expect(db.getTask('task_golden_path')?.isCompleted, isTrue);
      expect(db.getTotalXP(), equals(20));
      expect(db.getStreak().currentStreak, greaterThanOrEqualTo(1));
      expect(db.getProofsForTask('task_golden_path').length, equals(1));
      expect(db.getProofsForTask('task_golden_path').first.isVerified, isTrue);
    });
  });
}
