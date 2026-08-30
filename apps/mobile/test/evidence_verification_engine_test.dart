// Habitat Authoritative Evidence Verification Engine Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/proof/domain/capture_result.dart';
import 'package:habitat_mobile/features/proof/domain/evidence_verification_engine.dart';

void main() {
  late EvidenceVerificationEngine engine;

  setUp(() {
    engine = EvidenceVerificationEngine();
  });

  group('EvidenceVerificationEngine Phase 14 Tests', () {
    test('Rule 1: Valid Photo Proof passes all verification checks', () async {
      final task = LocalTask(
        id: 'task_001',
        title: 'Make Bed',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final capture = CaptureResult(
        filePath: 'app_storage://proofs/bed.jpg',
        mimeType: 'image/jpeg',
        byteSize: 1024 * 512,
        sha256Checksum: '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff',
        capturedAt: DateTime.now(),
      );

      final result = await engine.verifyEvidence(capture, task: task, attemptId: 'attempt_01');
      expect(result.isPassed, isTrue);
      expect(result.failedRules.isEmpty, isTrue);
      expect(result.confidenceScore, greaterThan(0.9));
    });

    test('Rule 2: Video Proof with duration >= 3s passes verification', () async {
      final task = LocalTask(
        id: 'task_002',
        title: '15 Pushups',
        category: 'PHYSICAL',
        taskType: 'VIDEO',
        requiresVideo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final capture = CaptureResult(
        filePath: 'app_storage://proofs/pushups.mp4',
        mimeType: 'video/mp4',
        byteSize: 1024 * 1024 * 4,
        sha256Checksum: '2222333344445555666677778888999900001111aaaabbbbccccddddeeeeffff',
        durationSeconds: 15,
        capturedAt: DateTime.now(),
      );

      final result = await engine.verifyEvidence(capture, task: task, attemptId: 'attempt_02');
      expect(result.isPassed, isTrue);
    });

    test('Rule 3: Video Proof with duration < 3s is rejected', () async {
      final task = LocalTask(
        id: 'task_003',
        title: 'Pushups',
        category: 'PHYSICAL',
        taskType: 'VIDEO',
        requiresVideo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final shortCapture = CaptureResult(
        filePath: 'app_storage://proofs/short.mp4',
        mimeType: 'video/mp4',
        byteSize: 1024 * 100,
        sha256Checksum: '3333444455556666777788889999000011112222aaaabbbbccccddddeeeeffff',
        durationSeconds: 2,
        capturedAt: DateTime.now(),
      );

      final result = await engine.verifyEvidence(shortCapture, task: task, attemptId: 'attempt_03');
      expect(result.isPassed, isFalse);
      expect(result.failedRules, contains('VIDEO_DURATION_TOO_SHORT'));
    });

    test('Rule 4: Anti-Replay duplicate SHA-256 hash is rejected', () async {
      final task1 = LocalTask(
        id: 'task_004',
        title: 'Drink Water',
        category: 'HEALTH',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final task2 = LocalTask(
        id: 'task_005',
        title: 'Drink Water Afternoon',
        category: 'HEALTH',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      const duplicateHash = '4444555566667777888899990000111122223333aaaabbbbccccddddeeeeffff';

      final capture1 = CaptureResult(
        filePath: 'app_storage://proofs/water1.jpg',
        mimeType: 'image/jpeg',
        byteSize: 1024 * 200,
        sha256Checksum: duplicateHash,
        capturedAt: DateTime.now(),
      );

      // First submission passes
      final res1 = await engine.verifyEvidence(capture1, task: task1, attemptId: 'att_1');
      expect(res1.isPassed, isTrue);

      // Second submission with exact same hash is rejected
      final res2 = await engine.verifyEvidence(capture1, task: task2, attemptId: 'att_2');
      expect(res2.isPassed, isFalse);
      expect(res2.failedRules, contains('DUPLICATE_PROOF_REPLAY_DETECTED'));
    });

    test('Rule 5: Stale Proof captured > 10 min prior is rejected', () async {
      final task = LocalTask(
        id: 'task_006',
        title: 'Brush Teeth',
        category: 'HEALTH',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final staleCapture = CaptureResult(
        filePath: 'app_storage://proofs/old_brush.jpg',
        mimeType: 'image/jpeg',
        byteSize: 1024 * 200,
        sha256Checksum: '5555666677778888999900001111222233334444aaaabbbbccccddddeeeeffff',
        capturedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );

      final result = await engine.verifyEvidence(staleCapture, task: task, attemptId: 'att_stale');
      expect(result.isPassed, isFalse);
      expect(result.failedRules, contains('PROOF_EXPIRED_STALE'));
    });

    test('Rule 6: Task category mismatch (Photo provided for Video-required task) is rejected', () async {
      final physicalTask = LocalTask(
        id: 'task_007',
        title: '50 Pushups',
        category: 'PHYSICAL',
        taskType: 'VIDEO',
        requiresVideo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final photoCapture = CaptureResult(
        filePath: 'app_storage://proofs/still_pushup.jpg',
        mimeType: 'image/jpeg',
        byteSize: 1024 * 200,
        sha256Checksum: '6666777788889999000011112222333344445555aaaabbbbccccddddeeeeffff',
        durationSeconds: 0,
        capturedAt: DateTime.now(),
      );

      final result = await engine.verifyEvidence(photoCapture, task: physicalTask, attemptId: 'att_mismatch');
      expect(result.isPassed, isFalse);
      expect(result.failedRules, contains('REQUIRED_VIDEO_PROOF_MISSING'));
    });
  });
}
