// Habitat Media Action Capture & Verification Service
import 'package:flutter/foundation.dart';

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

  factory MediaActionService.create() {
    return DefaultMediaActionService();
  }
}

class DefaultMediaActionService implements MediaActionService {
  @override
  Future<ActionResult> capturePhoto() async {
    // In production, launches Camera capture HUD and processes frame with MoveNet
    return const ActionResult(isSuccess: true, mediaPath: 'local://proof_photo.jpg', confidenceScore: 0.95);
  }

  @override
  Future<ActionResult> captureVideo() async {
    // In production, records motion reps and verifies liveness
    return const ActionResult(isSuccess: true, mediaPath: 'local://proof_video.mp4', confidenceScore: 0.92);
  }
}
