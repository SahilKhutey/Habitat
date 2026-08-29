// Habitat Canonical Task Domain Model
import 'package:flutter/foundation.dart';
import 'action_model.dart';
import 'alarm_model.dart';
import 'retry_rules_model.dart';
import 'schedule_model.dart';

enum TaskCategory {
  morning,
  physical,
  personal,
  mind,
  environment,
  routine,
  custom,
}

enum TaskDifficulty {
  easy,
  medium,
  hard,
}

enum TaskStatus {
  draft,
  scheduled,
  ready,
  active,
  completed,
  failed,
  missed,
  paused,
  archived,
}

@immutable
class TaskModel {
  final String id;
  final String title;
  final String description;
  final TaskCategory category;
  final TaskDifficulty difficulty;
  final TaskStatus status;
  final int baseXp;
  final int estimatedDurationSec;
  final TaskScheduleModel schedule;
  final TaskActionModel action;
  final TaskAlarmModel? alarm;
  final TaskRetryRulesModel retryRules;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.category,
    this.difficulty = TaskDifficulty.medium,
    this.status = TaskStatus.ready,
    this.baseXp = 30,
    this.estimatedDurationSec = 60,
    required this.schedule,
    required this.action,
    this.alarm,
    this.retryRules = const TaskRetryRulesModel(),
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskCategory? category,
    TaskDifficulty? difficulty,
    TaskStatus? status,
    int? baseXp,
    int? estimatedDurationSec,
    TaskScheduleModel? schedule,
    TaskActionModel? action,
    TaskAlarmModel? alarm,
    TaskRetryRulesModel? retryRules,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      baseXp: baseXp ?? this.baseXp,
      estimatedDurationSec: estimatedDurationSec ?? this.estimatedDurationSec,
      schedule: schedule ?? this.schedule,
      action: action ?? this.action,
      alarm: alarm ?? this.alarm,
      retryRules: retryRules ?? this.retryRules,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get categoryDisplayName => switch (category) {
        TaskCategory.morning => 'MORNING',
        TaskCategory.physical => 'EXERCISE',
        TaskCategory.mind => 'MIND',
        TaskCategory.environment => 'ENVIRONMENT',
        TaskCategory.personal => 'PERSONAL',
        TaskCategory.routine => 'ROUTINE',
        TaskCategory.custom => 'CUSTOM',
      };
}
