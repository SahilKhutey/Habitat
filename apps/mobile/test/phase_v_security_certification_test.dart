// Automated Test Suite for Phase V: Security, Privacy & Abuse-Resistance Certification
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/services/mission_execution_service.dart';
import 'package:habitat_mobile/services/native_alarm_scheduler.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalDatabase db;
  late MissionExecutionService missionService;
  late NativeAlarmScheduler scheduler;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    db = LocalDatabase.instance;
    db.resetAllData(populateDefaultTemplates: false);
    missionService = MissionExecutionService(database: db);
    scheduler = NativeAlarmScheduler.instance;
    scheduler.reset();
  });

  group('Phase V: Proof Tampering & Integrity Hardening (SEC-001, SEC-004)',
      () {
    test(
        'SEC-004: Tampered proof with invalid SHA-256 hash or empty file is strictly rejected',
        () async {
      final task = LocalTask(
        id: 'task_sec_tamper',
        title: 'Morning Pushup Set',
        category: 'PHYSICAL',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_sec_tamper');

      // 1. Attack: Empty file path
      final resEmpty = await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: '',
          sha256Checksum:
              '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff',
        ),
      );
      expect(resEmpty.isPassed, isFalse);

      // 2. Attack: Truncated/tampered checksum
      bool hashRejected = false;
      try {
        final resBadHash = await missionService.submitProof(
          attempt.id,
          const ProofSubmission(
            type: 'PHOTO',
            filePath: 'habitat_storage://proofs/tampered.jpg',
            sha256Checksum: 'not_a_valid_64_hex_checksum',
          ),
        );
        hashRejected = !resBadHash.isPassed;
      } catch (_) {
        hashRejected = true;
      }
      expect(hashRejected, isTrue);

      // 3. Complete attempt must fail
      final completeRes = await missionService.complete(attempt.id);
      expect(completeRes.isSuccess, isFalse);
      expect(db.getTotalXP(), equals(0));
      expect(db.getTask('task_sec_tamper')?.isCompleted, isFalse);
    });

    test('SEC-001: Proof Replay Attack across different attempts is rejected',
        () async {
      final taskA = LocalTask(
        id: 'task_sec_a',
        title: 'Task A',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final taskB = LocalTask(
        id: 'task_sec_b',
        title: 'Task B',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(taskA);
      db.saveTask(taskB);

      final attemptA = await missionService.start('task_sec_a');
      const validProofSubmission = ProofSubmission(
        type: 'PHOTO',
        filePath: 'habitat_storage://proofs/shared_proof.jpg',
        sha256Checksum:
            'aaaabbbbccccddddeeeeffff0000111122223333444455556666777788889999',
      );

      // Attempt A succeeds
      final proofA =
          await missionService.submitProof(attemptA.id, validProofSubmission);
      expect(proofA.isPassed, isTrue);
      final compA = await missionService.complete(attemptA.id);
      expect(compA.isSuccess, isTrue);

      // Attack: Attempt B tries to reuse the exact same local proof path
      final attemptB = await missionService.start('task_sec_b');
      final proofB =
          await missionService.submitProof(attemptB.id, validProofSubmission);
      expect(proofB.isPassed, isFalse); // Proof reuse rejected
      expect(proofB.failureReason, contains('reuse'));

      final compB = await missionService.complete(attemptB.id);
      expect(compB.isSuccess, isFalse);
    });
  });

  group('Phase V: XP, Streak & Alarm Replay Defense (SEC-002, SEC-005)', () {
    test(
        'SEC-002: Replayed completion requests cannot duplicate XP or streak rewards',
        () async {
      final task = LocalTask(
        id: 'task_sec_replay',
        title: 'Cold Shower',
        category: 'HEALTH',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_sec_replay');
      await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/shower_valid.jpg',
          sha256Checksum:
              '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
        ),
      );

      // Initial completion
      final res1 = await missionService.complete(attempt.id);
      expect(res1.isSuccess, isTrue);
      expect(res1.earnedXp, equals(20));
      expect(db.getTotalXP(), equals(20));

      // Replay attack: multiple immediate and delayed completion calls
      for (int i = 0; i < 5; i++) {
        final replayRes = await missionService.complete(attempt.id);
        expect(replayRes.isSuccess, isTrue);
        expect(replayRes.earnedXp, equals(0)); // 0 additional XP
      }

      expect(db.getTotalXP(), equals(20));
      expect(db.getStreak().currentStreak, equals(1));
    });

    test(
        'SEC-005: Stale alarm callbacks cannot mutate state once mission is complete',
        () {
      final occurrence = scheduler.scheduleExactAlarm(
        alarmId: 'alm_sec_stale',
        missionId: 'task_sec_stale',
        scheduledAt: DateTime.now(),
      );

      // Mission completed -> disarm
      scheduler.onMissionCompleted(occurrenceId: occurrence.occurrenceId);
      expect(occurrence.isCancelled, isTrue);

      // Stale callback replay
      scheduler.onMissionCompleted(occurrenceId: occurrence.occurrenceId);
      expect(occurrence.isCancelled, isTrue);
    });
  });
}
