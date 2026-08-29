// Habitat Alarm Domain Model
import 'package:flutter/foundation.dart';

enum DisciplineMode {
  gentle,
  discipline,
  hardcore,
}

@immutable
class TaskAlarmModel {
  final String id;
  final String taskId;
  final String timeOfDay; // HH:mm format, e.g. "07:00"
  final bool isEnabled;
  final List<int> repeatDays;
  final int retryIntervalMinutes;
  final int maxRetries;
  final int sirenVolume;
  final DisciplineMode disciplineMode;
  final DateTime? nextTrigger;

  const TaskAlarmModel({
    required this.id,
    required this.taskId,
    required this.timeOfDay,
    this.isEnabled = true,
    this.repeatDays = const [1, 2, 3, 4, 5, 6, 7],
    this.retryIntervalMinutes = 5,
    this.maxRetries = 3,
    this.sirenVolume = 70,
    this.disciplineMode = DisciplineMode.discipline,
    this.nextTrigger,
  });

  TaskAlarmModel copyWith({
    String? id,
    String? taskId,
    String? timeOfDay,
    bool? isEnabled,
    List<int>? repeatDays,
    int? retryIntervalMinutes,
    int? maxRetries,
    int? sirenVolume,
    DisciplineMode? disciplineMode,
    DateTime? nextTrigger,
  }) {
    return TaskAlarmModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      retryIntervalMinutes: retryIntervalMinutes ?? this.retryIntervalMinutes,
      maxRetries: maxRetries ?? this.maxRetries,
      sirenVolume: sirenVolume ?? this.sirenVolume,
      disciplineMode: disciplineMode ?? this.disciplineMode,
      nextTrigger: nextTrigger ?? this.nextTrigger,
    );
  }

  String get modeDisplayName => switch (disciplineMode) {
        DisciplineMode.gentle => 'GENTLE',
        DisciplineMode.discipline => 'DISCIPLINE',
        DisciplineMode.hardcore => 'HARDCORE',
      };
}
