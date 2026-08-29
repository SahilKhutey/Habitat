// Habitat Task Action Domain Model
import 'package:flutter/foundation.dart';

enum ActionType {
  checklist,
  photo,
  video,
  timer,
  confirmation,
}

@immutable
class HabitatAction {
  final String id;
  final String taskId;
  final ActionType type;
  final Map<String, dynamic> configuration;
  final bool isCompleted;
  final DateTime? verifiedAt;

  const HabitatAction({
    required this.id,
    required this.taskId,
    required this.type,
    this.configuration = const {},
    this.isCompleted = false,
    this.verifiedAt,
  });

  HabitatAction copyWith({
    String? id,
    String? taskId,
    ActionType? type,
    Map<String, dynamic>? configuration,
    bool? isCompleted,
    DateTime? verifiedAt,
  }) {
    return HabitatAction(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      type: type ?? this.type,
      configuration: configuration ?? this.configuration,
      isCompleted: isCompleted ?? this.isCompleted,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}
