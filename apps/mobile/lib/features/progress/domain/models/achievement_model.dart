// Habitat Achievement Domain Model
import 'package:flutter/foundation.dart';

enum AchievementCategory {
  tasks,
  streaks,
  speed,
  health,
  milestones,
}

@immutable
class AchievementModel {
  final String id;
  final String code;
  final String name;
  final String description;
  final AchievementCategory category;
  final String iconName;
  final int xpReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progressPercent; // 0.0 to 1.0

  const AchievementModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.category,
    this.iconName = 'emoji_events',
    required this.xpReward,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progressPercent = 0.0,
  });

  String get categoryDisplayName => switch (category) {
        AchievementCategory.tasks => 'Tasks',
        AchievementCategory.streaks => 'Streaks',
        AchievementCategory.speed => 'Instant Action',
        AchievementCategory.health => 'Health & Recovery',
        AchievementCategory.milestones => 'Milestones',
      };
}
