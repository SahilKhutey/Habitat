// Canonical Mission & Attempt Models
import 'alarm.dart';

enum MissionStatus {
  scheduled,
  triggered,
  active,
  proofSubmitted,
  verifying,
  completed,
  failed,
  retrying
}

class Mission {
  final String id;
  final String userId;
  final String? alarmId;
  final String taskId;
  final DateTime scheduledAt;
  final DateTime? triggeredAt;
  final DateTime? completedAt;
  final MissionStatus status;
  final int attemptCount;
  final int? resistanceSeconds;
  final DisciplineMode disciplineMode;
  final String? idempotencyKey;
  final DateTime createdAt;

  const Mission({
    required this.id,
    required this.userId,
    this.alarmId,
    required this.taskId,
    required this.scheduledAt,
    this.triggeredAt,
    this.completedAt,
    this.status = MissionStatus.scheduled,
    this.attemptCount = 0,
    this.resistanceSeconds,
    this.disciplineMode = DisciplineMode.discipline,
    this.idempotencyKey,
    required this.createdAt,
  });

  double get resistanceMinutes =>
      resistanceSeconds == null ? 0.0 : (resistanceSeconds! / 60.0);

  Mission copyWith({
    MissionStatus? status,
    DateTime? triggeredAt,
    DateTime? completedAt,
    int? attemptCount,
    int? resistanceSeconds,
    String? idempotencyKey,
  }) {
    return Mission(
      id: id,
      userId: userId,
      alarmId: alarmId,
      taskId: taskId,
      scheduledAt: scheduledAt,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      resistanceSeconds: resistanceSeconds ?? this.resistanceSeconds,
      disciplineMode: disciplineMode,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'alarmId': alarmId,
        'taskId': taskId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'triggeredAt': triggeredAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'status': status.name.toUpperCase(),
        'attemptCount': attemptCount,
        'resistanceSeconds': resistanceSeconds,
        'disciplineMode': disciplineMode.name.toUpperCase(),
        'idempotencyKey': idempotencyKey,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
        id: json['id'] as String,
        userId: json['userId'] as String,
        alarmId: json['alarmId'] as String?,
        taskId: json['taskId'] as String,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        triggeredAt: json['triggeredAt'] != null ? DateTime.parse(json['triggeredAt'] as String) : null,
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
        status: MissionStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['status'] as String).toLowerCase(),
          orElse: () => MissionStatus.scheduled,
        ),
        attemptCount: json['attemptCount'] as int? ?? 0,
        resistanceSeconds: json['resistanceSeconds'] as int?,
        disciplineMode: DisciplineMode.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['disciplineMode'] as String).toLowerCase(),
          orElse: () => DisciplineMode.discipline,
        ),
        idempotencyKey: json['idempotencyKey'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class MissionAttempt {
  final String id;
  final String missionId;
  final int attemptIndex;
  final DateTime triggeredAt;
  final DateTime? resolvedAt;
  final String status; // 'IGNORED', 'FAILED', 'PASSED'
  final int sirenVolumeLevel;

  const MissionAttempt({
    required this.id,
    required this.missionId,
    required this.attemptIndex,
    required this.triggeredAt,
    this.resolvedAt,
    this.status = 'IGNORED',
    this.sirenVolumeLevel = 70,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'missionId': missionId,
        'attemptIndex': attemptIndex,
        'triggeredAt': triggeredAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'status': status,
        'sirenVolumeLevel': sirenVolumeLevel,
      };
}
