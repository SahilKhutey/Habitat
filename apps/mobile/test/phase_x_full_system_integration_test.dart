// Master Acceptance & System Certification Suite for Phase X: Final Product Integration & Full-System Certification
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
    scheduler.reset();
  });

  group('Phase X: Full End-to-End System Integration Gate', () {
    test(
        'X1–X15: Complete Certified Path: Task -> Alarm -> Trigger -> Proof -> Atomic Completion -> XP -> Streak -> Persistence -> Recovery',
        () async {
      // ───────────────────────────────────────────────────────────────────────
      // 1. FRESH PROFILE & TASK CREATION (X4, X5)
      // ───────────────────────────────────────────────────────────────────────
      final profile = db.getOrCreateProfile(name: 'Commander Sentinel');
      expect(profile.displayName, equals('Commander Sentinel'));

      final task = LocalTask(
        id: 'task_phase_x_master',
        title: 'Dawn Push-up Protocol',
        category: 'PHYSICAL',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final alarm = LocalAlarm(
        id: 'alm_phase_x_master',
        taskId: 'task_phase_x_master',
        scheduledTime: '06:00',
        enabled: true,
        createdAt: DateTime.now(),
      );
      db.saveAlarm(alarm);

      expect(db.getAllTasks().length, equals(1));
      expect(db.getAllAlarms().length, equals(1));

      // ───────────────────────────────────────────────────────────────────────
      // 2. STARTUP RECONCILIATION & OS EXACT ALARM SCHEDULING (X6, X14)
      // ───────────────────────────────────────────────────────────────────────
      final reconciledCount =
          await alarmService.reconcilePersistedAlarmsOnStartup();
      expect(reconciledCount, equals(1));

      final occurrence = scheduler.scheduleExactAlarm(
        alarmId: 'alm_phase_x_master',
        missionId: 'task_phase_x_master',
        scheduledAt: DateTime.now(),
      );
      expect(occurrence.isDisarmed, isFalse);

      // ───────────────────────────────────────────────────────────────────────
      // 3. NOTIFICATION & MISSION LAUNCH (X7, X8)
      // ───────────────────────────────────────────────────────────────────────
      final attempt = await missionService.start('task_phase_x_master',
          alarmId: 'alm_phase_x_master');
      expect(attempt.status, equals('AWAITING_ACTION'));

      // ───────────────────────────────────────────────────────────────────────
      // 4. CAMERA PROOF CAPTURE & INTEGRITY VERIFICATION (X9, X10)
      // ───────────────────────────────────────────────────────────────────────
      const proofPayload = ProofSubmission(
        type: 'PHOTO',
        filePath: 'habitat_storage://proofs/phase_x_pushup.jpg',
        sha256Checksum:
            '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff',
      );

      final verification =
          await missionService.submitProof(attempt.id, proofPayload);
      expect(verification.isPassed, isTrue);

      final verifiedAttempt = db.getAttempt(attempt.id);
      expect(verifiedAttempt?.status, equals('PROOF_VERIFIED'));

      // ───────────────────────────────────────────────────────────────────────
      // 5. ATOMIC COMPLETION, XP, STREAK & RETRY DISARMING (X11, X12)
      // ───────────────────────────────────────────────────────────────────────
      final completion = await missionService.complete(attempt.id);
      expect(completion.isSuccess, isTrue);
      expect(completion.earnedXp, equals(20));
      expect(completion.currentStreak, equals(1));

      scheduler.onMissionCompleted(occurrenceId: occurrence.occurrenceId);
      expect(occurrence.isCancelled, isTrue);

      expect(db.getTask('task_phase_x_master')?.isCompleted, isTrue);
      expect(db.getTotalXP(), equals(20));
      expect(db.getStreak().currentStreak, equals(1));

      // ───────────────────────────────────────────────────────────────────────
      // 6. IDEMPOTENCY & REPLAY DEFENSE (X11, X18)
      // ───────────────────────────────────────────────────────────────────────
      final duplicateCompletion = await missionService.complete(attempt.id);
      expect(duplicateCompletion.isSuccess, isTrue);
      expect(duplicateCompletion.earnedXp, equals(0)); // Idempotent 0 extra XP
      expect(db.getTotalXP(), equals(20));
      expect(db.getStreak().currentStreak, equals(1));

      // ───────────────────────────────────────────────────────────────────────
      // 7. DISK SERIALIZATION & COLD RESTARTS / RECOVERY (X13, X19)
      // ───────────────────────────────────────────────────────────────────────
      await db.flush();
      final diskSnapshot = db.exportCompleteStateJson();

      db.resetAllData(populateDefaultTemplates: false);
      expect(db.getAllTasks().isEmpty, isTrue);

      // Hydrate from cold persistence
      db.restoreFromStateJson(diskSnapshot);

      expect(db.getTask('task_phase_x_master')?.isCompleted, isTrue);
      expect(db.getTotalXP(), equals(20));
      expect(db.getStreak().currentStreak, equals(1));
      expect(db.getProofsForTask('task_phase_x_master').length, equals(1));
      expect(
          db.getProofsForTask('task_phase_x_master').first.isVerified, isTrue);
    });
  });
}
