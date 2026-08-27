// Canonical Proof, XP Transaction, and Streak Models
enum VerificationStatus { pending, accepted, rejected }

class Proof {
  final String id;
  final String missionId;
  final String mediaType; // 'image/jpeg', 'video/mp4'
  final String storageKey;
  final DateTime capturedAt;
  final Map<String, dynamic> deviceTelemetry;
  final VerificationStatus verificationStatus;
  final String? rejectionReason;
  final DateTime createdAt;

  const Proof({
    required this.id,
    required this.missionId,
    required this.mediaType,
    required this.storageKey,
    required this.capturedAt,
    this.deviceTelemetry = const {},
    this.verificationStatus = VerificationStatus.pending,
    this.rejectionReason,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'missionId': missionId,
        'mediaType': mediaType,
        'storageKey': storageKey,
        'capturedAt': capturedAt.toIso8601String(),
        'deviceTelemetry': deviceTelemetry,
        'verificationStatus': verificationStatus.name.toUpperCase(),
        'rejectionReason': rejectionReason,
        'createdAt': createdAt.toIso8601String(),
      };
}

class XpTransaction {
  final String id;
  final String userId;
  final String? missionId;
  final int amount;
  final String reason; // 'MISSION_COMPLETED', 'FIRST_ATTEMPT_BONUS', 'STREAK_BONUS'
  final DateTime createdAt;

  const XpTransaction({
    required this.id,
    required this.userId,
    this.missionId,
    required this.amount,
    required this.reason,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'missionId': missionId,
        'amount': amount,
        'reason': reason,
        'createdAt': createdAt.toIso8601String(),
      };
}

class Streak {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final int graceTokens;
  final String? lastCompletedDate; // 'YYYY-MM-DD'
  final DateTime updatedAt;

  const Streak({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.graceTokens = 1,
    this.lastCompletedDate,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'graceTokens': graceTokens,
        'lastCompletedDate': lastCompletedDate,
        'updatedAt': updatedAt.toIso8601String(),
      };
}
