// Habitat Media Action Capture & Verification Service
import 'package:flutter/foundation.dart';
import '../../../../features/proof/data/camera_service.dart';

@immutable
class ActionResult {
  final bool isSuccess;
  final String? mediaPath;
  final double confidenceScore;
  final String? errorMessage;

  const ActionResult({
    required this.isSuccess,
    this.mediaPath,
    this.confidenceScore = 1.0,
    this.errorMessage,
  });

  static const ActionResult success = ActionResult(isSuccess: true, confidenceScore: 1.0);
  
  static ActionResult failure(String message) =>
      ActionResult(isSuccess: false, confidenceScore: 0.0, errorMessage: message);
}

abstract interface class MediaActionService {
  Future<ActionResult> capturePhoto();
  Future<ActionResult> captureVideo();

  factory MediaActionService.create({ICameraService? cameraService}) {
    return DefaultMediaActionService(cameraService: cameraService);
  }
}

class DefaultMediaActionService implements MediaActionService {
  final ICameraService _cameraService;

  DefaultMediaActionService({ICameraService? cameraService})
      : _cameraService = cameraService ?? CameraService();

  @override
  Future<ActionResult> capturePhoto() async {
    try {
      final res = await _cameraService.takePhoto(taskId: 'general', attemptId: 'default');
      return ActionResult(
        isSuccess: true,
        mediaPath: res.filePath,
        confidenceScore: 1.0,
      );
    } catch (e) {
      return ActionResult.failure(e.toString());
    }
  }

  @override
  Future<ActionResult> captureVideo() async {
    try {
      await _cameraService.startVideoRecording();
      final res = await _cameraService.stopVideoRecording(taskId: 'general', attemptId: 'default');
      return ActionResult(
        isSuccess: true,
        mediaPath: res.filePath,
        confidenceScore: 1.0,
      );
    } catch (e) {
      return ActionResult.failure(e.toString());
    }
  }
}

