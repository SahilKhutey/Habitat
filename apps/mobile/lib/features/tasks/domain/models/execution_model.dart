// Habitat Execution & Attempt Domain Model
import 'package:flutter/foundation.dart';

enum ExecutionStatus {
  scheduled,
  triggered,
  inProgress,
  verifying,
  completed,
  failed,
  retrying,
}

@immutable
class TaskExecutionModel {
  final String attemptId;
  final String taskId;
  final String taskTitle;
  final String alarmId;
  final int attemptNumber;
  final ExecutionStatus status;
  final DateTime triggeredAt;
  final DateTime? completedAt;
  final int resistanceSeconds; // ΔtR (time taken to act)
  final bool isSpeedBonus; // true if under 2 minutes (120s)
  final String? proofPath;
  final String proofType; // 'PHOTO', 'VIDEO', 'MANUAL'
  final bool isVerified;
  final int xpAwarded;

  const TaskExecutionModel({
    required this.attemptId,
    required this.taskId,
    required this.taskTitle,
    required this.alarmId,
    this.attemptNumber = 1,
    this.status = ExecutionStatus.inProgress,
    required this.triggeredAt,
    this.completedAt,
    this.resistanceSeconds = 0,
    this.isSpeedBonus = false,
    this.proofPath,
    this.proofType = 'PHOTO',
    this.isVerified = false,
    this.xpAwarded = 0,
  });

  String get formattedResistanceTime {
    final m = (resistanceSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (resistanceSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
