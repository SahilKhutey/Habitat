// Habitat Action Domain Model
import 'package:flutter/foundation.dart';

enum ActionType {
  photo,
  video,
  timer,
  confirmation,
  custom,
}

enum VerificationType {
  photoProof,
  videoProof,
  timerElapsed,
  manualConfirm,
  aiObjectDetect,
}

@immutable
class TaskActionModel {
  final String id;
  final ActionType type;
  final String title;
  final String instruction;
  final VerificationType verificationType;
  final Map<String, dynamic> parameters;
  final String iconName;

  const TaskActionModel({
    required this.id,
    required this.type,
    required this.title,
    required this.instruction,
    required this.verificationType,
    this.parameters = const {},
    this.iconName = 'camera_alt',
  });

  String get typeDisplayName => switch (type) {
        ActionType.photo => 'Photo Verification',
        ActionType.video => 'Video AI Pose Verification',
        ActionType.timer => 'Timer Adherence',
        ActionType.confirmation => 'Manual Check-in',
        ActionType.custom => 'Custom Proof',
      };
}
