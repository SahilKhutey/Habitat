// Habitat Mission Execution & Verification Service Unit & Integration Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/services/mission_execution_service.dart';

void main() {
  late LocalDatabase db;
  late MissionExecutionService missionService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    missionService = MissionExecutionService(database: db);
  });

  group('MissionExecutionService Core Tests', () {
    test(
        'Test 1 — Proof Bypass: direct completion of proof-required task is rejected',
        () {
      final task = LocalTask(
        id: 'task_bypass_test',
        title: '50 Pushups',
        category: 'PHYSICAL',
        taskType: 'VIDEO',
        requiresVideo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      expect(
        () => db.completeTask('task_bypass_test'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Task requires a verified proof before completion'),
        )),
      );
    });

    test('Test 2 — Valid Photo Proof: verification passes and awards +20 XP',
        () async {
      final task = LocalTask(
        id: 'task_photo_test',
        title: 'Make Bed',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      // Start Mission
      final attempt = await missionService.start('task_photo_test');
      expect(attempt.status, equals('AWAITING_ACTION'));

      // Submit Valid Photo Proof
      final verification = await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/bed.jpg',
          sha256Checksum:
              'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        ),
      );
      expect(verification.isPassed, isTrue);

      final updatedAttempt = db.getAttempt(attempt.id);
      expect(updatedAttempt?.status, equals('PROOF_VERIFIED'));

      // Complete Mission
      final result = await missionService.complete(attempt.id);
      expect(result.isSuccess, isTrue);
      expect(result.earnedXp, equals(20));

      final completedTask = db.getTask('task_photo_test');
      expect(completedTask?.isCompleted, isTrue);
      expect(db.getTotalXP(), equals(20));
    });

    test('Test 3 — Invalid Video (< 3s): rejected by verification engine',
        () async {
      final task = LocalTask(
        id: 'task_video_test',
        title: '15 Pushups',
        category: 'EXERCISE',
        taskType: 'VIDEO',
        requiresVideo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_video_test');

      // Submit short video (< 3 seconds)
      final verification = await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'VIDEO',
          filePath: 'habitat_storage://proofs/short_pushups.mp4',
          sha256Checksum:
              '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          durationSeconds: 2,
        ),
      );

      expect(verification.isPassed, isFalse);
      expect(verification.failureReason, contains('at least 3 seconds'));

      final updatedAttempt = db.getAttempt(attempt.id);
      expect(updatedAttempt?.status, equals('FAILED'));
    });

    test('Test 4 — Duplicate Completion: idempotent XP awarding', () async {
      final task = LocalTask(
        id: 'task_idempotency_test',
        title: 'Drink 500ml Water',
        category: 'HEALTH',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_idempotency_test');
      await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/water.jpg',
          sha256Checksum:
              '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff',
        ),
      );

      // Complete once
      await missionService.complete(attempt.id);
      expect(db.getTotalXP(), equals(20));

      // Complete again with same attempt
      await missionService.complete(attempt.id);
      // XP should remain 20, not 40
      expect(db.getTotalXP(), equals(20));
    });

    test('Test 6 — Checksum Validation: non-64 hex SHA-256 is rejected',
        () async {
      final task = LocalTask(
        id: 'task_hash_test',
        title: 'Cold Shower',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_hash_test');
      expect(
        () => missionService.submitProof(
          attempt.id,
          const ProofSubmission(
            type: 'PHOTO',
            filePath: 'habitat_storage://proofs/shower.jpg',
            sha256Checksum: 'invalid_short_hash',
          ),
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Invalid proof SHA-256 checksum'),
        )),
      );
    });

    test(
        'Test 7 — Proof Reuse Prevention: duplicate submission of same file is rejected',
        () async {
      final task = LocalTask(
        id: 'task_reuse_test',
        title: 'Morning Walk',
        category: 'HEALTH',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt1 = await missionService.start('task_reuse_test');
      await missionService.submitProof(
        attempt1.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/walk.jpg',
          sha256Checksum:
              'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        ),
      );
      await missionService.complete(attempt1.id);

      final attempt2 = await missionService.start('task_reuse_test');
      expect(
        () => missionService.submitProof(
          attempt2.id,
          const ProofSubmission(
            type: 'PHOTO',
            filePath: 'habitat_storage://proofs/walk.jpg',
            sha256Checksum:
                'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
          ),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('already been submitted'),
        )),
      );
    });

    test(
        'Test 8 — Unverified Completion Guard: complete() throws if proof is missing',
        () async {
      final task = LocalTask(
        id: 'task_unverified_guard',
        title: 'Stretching',
        category: 'EXERCISE',
        taskType: 'VIDEO',
        requiresVideo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_unverified_guard');
      expect(
        () => missionService.complete(attempt.id),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Cannot complete mission: valid verified proof is required'),
        )),
      );
    });
  });
}
