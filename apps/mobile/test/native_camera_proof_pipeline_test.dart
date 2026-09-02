// Habitat Native Camera Proof Pipeline Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/core/platform/media/native_camera_proof_pipeline.dart';

void main() {
  late NativeCameraProofPipeline pipeline;
  late MediaVerificationEngine engine;

  setUp(() {
    pipeline = NativeCameraProofPipeline();
    engine = MediaVerificationEngine();
  });

  group('NativeCameraProofPipeline Tests', () {
    test('capturePhotoProof() generates real metadata and non-empty SHA-256 hash', () async {
      final photo = await pipeline.capturePhotoProof(
        taskId: 'task_001',
        attemptId: 'attempt_001',
      );

      expect(photo.filePath, contains('task_001_attempt_001_photo.jpg'));
      expect(photo.mimeType, equals('image/jpeg'));
      expect(photo.byteSize, greaterThan(0));
      expect(photo.sha256Checksum.length, equals(64));
      expect(photo.metadata['width'], equals(1920));
    });

    test('captureVideoProof() generates video metadata with duration', () async {
      final video = await pipeline.captureVideoProof(
        taskId: 'task_002',
        attemptId: 'attempt_002',
        durationSeconds: 10,
      );

      expect(video.filePath, contains('task_002_attempt_002_video.mp4'));
      expect(video.mimeType, equals('video/mp4'));
      expect(video.durationSeconds, equals(10));
      expect(video.sha256Checksum.isNotEmpty, isTrue);
    });

    test('verifyProof() fails when media checksum is empty', () async {
      final invalidFile = CapturedProofFile(
        filePath: 'test.jpg',
        mimeType: 'image/jpeg',
        byteSize: 0,
        sha256Checksum: '',
        capturedAt: DateTime.now(),
      );

      final result = await engine.verifyProof(invalidFile, requiredType: 'PHOTO');
      expect(result.isPassed, isFalse);
      expect(result.failureReason, contains('empty checksum or zero bytes'));
    });

    test('verifyProof() marks local integrity valid with serverVerificationPending', () async {
      final validFile = CapturedProofFile(
        filePath: 'test.jpg',
        mimeType: 'image/jpeg',
        byteSize: 1024 * 100,
        sha256Checksum: 'a' * 64,
        capturedAt: DateTime.now(),
      );

      final result = await engine.verifyProof(validFile, requiredType: 'PHOTO');
      expect(result.isPassed, isTrue);
      expect(result.details['localFormatValid'], isTrue);
      expect(result.details['serverVerificationPending'], isTrue);
    });
  });
}
