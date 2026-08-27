// Canonical Alarm (Commitment) Model
enum DisciplineMode { gentle, discipline, hardcore }

class Alarm {
  final String id;
  final String userId;
  final String taskId;
  final String timeOfDay; // 'HH:MM:SS'
  final String timezone;
  final List<int> repeatDays; // [0,1,2,3,4,5,6] (0=Sun, 6=Sat)
  final DisciplineMode disciplineMode;
  final int retryIntervalMinutes;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Alarm({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.timeOfDay,
    this.timezone = 'UTC',
    this.repeatDays = const [1, 2, 3, 4, 5],
    this.disciplineMode = DisciplineMode.discipline,
    this.retryIntervalMinutes = 5,
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'taskId': taskId,
        'timeOfDay': timeOfDay,
        'timezone': timezone,
        'repeatDays': repeatDays,
        'disciplineMode': disciplineMode.name.toUpperCase(),
        'retryIntervalMinutes': retryIntervalMinutes,
        'isEnabled': isEnabled,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        id: json['id'] as String,
        userId: json['userId'] as String,
        taskId: json['taskId'] as String,
        timeOfDay: json['timeOfDay'] as String,
        timezone: json['timezone'] as String? ?? 'UTC',
        repeatDays: (json['repeatDays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [1, 2, 3, 4, 5],
        disciplineMode: DisciplineMode.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['disciplineMode'] as String).toLowerCase(),
          orElse: () => DisciplineMode.discipline,
        ),
        retryIntervalMinutes: json['retryIntervalMinutes'] as int? ?? 5,
        isEnabled: json['isEnabled'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
