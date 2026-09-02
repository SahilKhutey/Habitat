// Automated Test Suite for Phase 3 / Track J8: Camera Service & Lifecycle Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/features/proof/data/camera_service.dart';

void main() {
  late CameraService cameraService;

  setUp(() {
    cameraService = CameraService();
  });

  group('Track J8: CameraService Hardware Abstraction Tests', () {
    test('Initial state is uninitialized and not recording', () {
      expect(cameraService.isInitialized, isFalse);
      expect(cameraService.isRecordingVideo, isFalse);
      expect(cameraService.isFrontCamera, isFalse);
    });

    test('initialize() transitions isInitialized to true', () async {
      await cameraService.initialize();
      expect(cameraService.isInitialized, isTrue);
    });

    test('switchCamera() toggles front/back lens state', () async {
      expect(cameraService.isFrontCamera, isFalse);
      await cameraService.switchCamera();
      expect(cameraService.isFrontCamera, isTrue);
      await cameraService.switchCamera();
      expect(cameraService.isFrontCamera, isFalse);
    });

    test('takePhoto() produces valid CaptureResult with SHA-256 and metadata', () async {
      await cameraService.initialize();
      final result = await cameraService.takePhoto(
        taskId: 'task_pushups',
        attemptId: 'att_001',
      );

      expect(result.filePath, contains('task_pushups_att_001_photo.jpg'));
      expect(result.mimeType, equals('image/jpeg'));
      expect(result.byteSize, greaterThan(0));
      expect(result.sha256Checksum.length, equals(64));
      expect(result.metadata['width'], equals(1920));
      expect(result.metadata['height'], equals(1080));
    });

    test('startVideoRecording() and stopVideoRecording() tracks duration and byte checksum', () async {
      await cameraService.initialize();
      await cameraService.startVideoRecording();
      expect(cameraService.isRecordingVideo, isTrue);

      final result = await cameraService.stopVideoRecording(
        taskId: 'task_pushups',
        attemptId: 'att_002',
      );

      expect(cameraService.isRecordingVideo, isFalse);
      expect(result.filePath, contains('task_pushups_att_002_video.mp4'));
      expect(result.mimeType, equals('video/mp4'));
      expect(result.durationSeconds, greaterThanOrEqualTo(0));
      expect(result.sha256Checksum.length, equals(64));
    });

    test('dispose() resets initialization and recording flags', () async {
      await cameraService.initialize();
      await cameraService.startVideoRecording();
      expect(cameraService.isInitialized, isTrue);
      expect(cameraService.isRecordingVideo, isTrue);

      await cameraService.dispose();
      expect(cameraService.isInitialized, isFalse);
      expect(cameraService.isRecordingVideo, isFalse);
    });
  });
}
