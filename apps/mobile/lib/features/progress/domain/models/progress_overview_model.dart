// Habitat Master Progress Overview Domain Model
import 'package:flutter/foundation.dart';
import 'achievement_model.dart';
import 'daily_summary.dart';
import 'streak_model.dart';
import 'weekly_summary.dart';

@immutable
class ProgressOverviewModel {
  final DailyProgressSummaryModel today;
  final WeeklyProgressSummaryModel thisWeek;
  final StreakModel streak;
  final List<AchievementModel> achievements;
  final int totalXp;

  const ProgressOverviewModel({
    required this.today,
    required this.thisWeek,
    required this.streak,
    required this.achievements,
    required this.totalXp,
  });

  int get unlockedAchievementsCount =>
      achievements.where((a) => a.isUnlocked).length;

  int get totalAchievementsCount => achievements.length;
}
