// Mission Domain Entities & Status State Machine in Flutter
enum MissionStatus {
  scheduled,
  active,
  inProgress,
  verifying,
  retry,
  completed,
  cancelled,
  expired,
  abandoned,
}

class MissionEntity {
  final String id;
  final String userId;
  final String taskId;
  final String? alarmId;
  final String taskTitle;
  final String taskInstructions;
  final String taskProofType;
  final int taskBaseXp;
  final MissionStatus status;
  final DateTime scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? nextRetryAt;
  final int attemptCount;
  final int retryCount;

  const MissionEntity({
    required this.id,
    required this.userId,
    required this.taskId,
    this.alarmId,
    required this.taskTitle,
    required this.taskInstructions,
    required this.taskProofType,
    required this.taskBaseXp,
    required this.status,
    required this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.nextRetryAt,
    this.attemptCount = 0,
    this.retryCount = 0,
  });
}
