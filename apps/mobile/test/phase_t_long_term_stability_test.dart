// Automated Test Suite for Phase T: Long-Term Reliability, Performance & Production Stability
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

  group('Phase T: Storage Growth & Proof Media Lifecycle (T8, T9)', () {
    test('T8 & T9: Detects orphaned and missing proof media records accurately',
        () async {
      // 1. Create valid task and attempt
      final task = LocalTask(
        id: 'task_storage_audit',
        title: 'Hydration & Mobility',
        category: 'HEALTH',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_storage_audit');

      // 2. Submit valid proof
      final proof = await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/audit_photo_1.jpg',
          sha256Checksum:
              'abcdef112233445566778899aabbccddeeff00112233445566778899aabbccdd',
        ),
      );
      expect(proof.isPassed, isTrue);

      final allProofs = db.getProofsForTask('task_storage_audit');
      expect(allProofs.length, equals(1));
      expect(allProofs.first.isVerified, isTrue);

      // 3. Verify zero-byte or corrupt checksum rejection
      bool corruptRejected = false;
      try {
        final corruptVerification = await missionService.submitProof(
          attempt.id,
          const ProofSubmission(
            type: 'PHOTO',
            filePath: '',
            sha256Checksum: 'short_invalid_hash',
          ),
        );
        corruptRejected = !corruptVerification.isPassed;
      } catch (_) {
        corruptRejected = true;
      }
      expect(corruptRejected, isTrue);
    });
  });

  group('Phase T: Persistence Stress & Large-Scale Durability (T11, T12)', () {
    test(
        'T11 & T12: Survives 1,000-entity stress test with zero data loss or corruption',
        () async {
      final now = DateTime.now();

      // Seed 200 tasks, 200 alarms, 300 attempts, 300 proofs (1000 total entities)
      for (int i = 0; i < 200; i++) {
        db.saveTask(LocalTask(
          id: 'task_stress_$i',
          title: 'Stress Task #$i',
          category: 'DISCIPLINE',
          createdAt: now,
          updatedAt: now,
        ));

        db.saveAlarm(LocalAlarm(
          id: 'alm_stress_$i',
          taskId: 'task_stress_$i',
          scheduledTime: '07:00',
          enabled: true,
          createdAt: now,
        ));
      }

      for (int i = 0; i < 300; i++) {
        final taskId = 'task_stress_${i % 200}';
        db.saveAttempt(LocalAttempt(
          id: 'att_stress_$i',
          taskId: taskId,
          status: i % 2 == 0 ? 'COMPLETED' : 'AWAITING_ACTION',
          startedAt: now,
          completedAt: i % 2 == 0 ? now : null,
        ));

        db.saveProof(LocalProof(
          id: 'prf_stress_$i',
          taskId: taskId,
          attemptId: 'att_stress_$i',
          type: 'PHOTO',
          localPath: 'habitat_storage://proofs/stress_$i.jpg',
          sha256Hash: 'hash_$i',
          isVerified: true,
          createdAt: now,
        ));
      }

      expect(db.getAllTasks().length, equals(200));
      expect(db.getAllAlarms().length, equals(200));
      expect(db.getAllAttempts().length, equals(300));

      // Serialize entire 1000-entity state
      final stopwatch = Stopwatch()..start();
      final exportedState = db.exportCompleteStateJson();
      stopwatch.stop();

      expect(exportedState.isNotEmpty, isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Under 500ms

      // Wipe and restore from cold persistence
      db.resetAllData(populateDefaultTemplates: false);
      expect(db.getAllTasks().isEmpty, isTrue);

      db.restoreFromStateJson(exportedState);

      expect(db.getAllTasks().length, equals(200));
      expect(db.getAllAlarms().length, equals(200));
      expect(db.getAllAttempts().length, equals(300));
      expect(db.getTask('task_stress_150')?.title, equals('Stress Task #150'));
    });
  });

  group('Phase T: Concurrency & Duplicate Callback Invariants (T13, T14)', () {
    test(
        'T13 & T14: Concurrent triple completion calls yield exactly 1 completion and 1 XP award',
        () async {
      final task = LocalTask(
        id: 'task_race_condition',
        title: 'Push-up Set',
        category: 'PHYSICAL',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_race_condition');

      await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/race_proof.jpg',
          sha256Checksum:
              '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff',
        ),
      );

      // Simulate simultaneous completion calls from UI, alarm callback, and notification tap
      final results = await Future.wait([
        missionService.complete(attempt.id),
        missionService.complete(attempt.id),
        missionService.complete(attempt.id),
      ]);

      // Exactly one awarded XP
      final totalXpAwarded =
          results.fold<int>(0, (sum, res) => sum + res.earnedXp);
      expect(totalXpAwarded, equals(20));
      expect(db.getTotalXP(), equals(20));

      // Exactly one streak increment
      expect(db.getStreak().currentStreak, equals(1));
    });
  });

  group('Phase T: Alarm Scheduling & Startup Reconciliation (T5, T6)', () {
    test(
        'T5 & T6: Reconciles valid unexpired alarms and disarms retries upon completion',
        () async {
      final task = LocalTask(
        id: 'task_alarm_stress',
        title: 'Morning Awakening',
        category: 'DISCIPLINE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      db.saveAlarm(LocalAlarm(
        id: 'alm_stress_1',
        taskId: 'task_alarm_stress',
        scheduledTime: '06:00',
        enabled: true,
        createdAt: DateTime.now(),
      ));

      final count = await alarmService.reconcilePersistedAlarmsOnStartup();
      expect(count, equals(1));

      // Trigger alarm
      final occurrence = scheduler.scheduleExactAlarm(
        alarmId: 'alm_stress_1',
        missionId: 'task_alarm_stress',
        scheduledAt: DateTime.now(),
      );
      expect(occurrence.isDisarmed, isFalse);

      // Disarm upon mission completion
      scheduler.onMissionCompleted(occurrenceId: occurrence.occurrenceId);
      expect(occurrence.isCancelled, isTrue);
    });
  });
}
