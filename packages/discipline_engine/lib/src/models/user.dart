// Canonical User Model
class User {
  final String id;
  final String email;
  final String displayName;
  final String timezone;
  final int disciplineScore;
  final int autonomyLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.timezone = 'UTC',
    this.disciplineScore = 100,
    this.autonomyLevel = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'timezone': timezone,
        'disciplineScore': disciplineScore,
        'autonomyLevel': autonomyLevel,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        timezone: json['timezone'] as String? ?? 'UTC',
        disciplineScore: json['disciplineScore'] as int? ?? 100,
        autonomyLevel: json['autonomyLevel'] as int? ?? 1,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
