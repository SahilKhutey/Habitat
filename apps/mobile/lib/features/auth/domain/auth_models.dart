// Auth Domain Models
class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String timezone;
  final int disciplineScore;
  final int autonomyLevel;
  final int currentStreak;
  final int longestStreak;
  final int graceTokens;
  final int totalXp;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.timezone = 'UTC',
    this.disciplineScore = 100,
    this.autonomyLevel = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.graceTokens = 1,
    this.totalXp = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        timezone: json['timezone'] as String? ?? 'UTC',
        disciplineScore: json['disciplineScore'] as int? ?? 100,
        autonomyLevel: json['autonomyLevel'] as int? ?? 1,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        graceTokens: json['graceTokens'] as int? ?? 1,
        totalXp: json['totalXp'] as int? ?? 0,
      );
}

class AuthSession {
  final UserProfile user;
  final String token;

  const AuthSession({
    required this.user,
    required this.token,
  });
}
