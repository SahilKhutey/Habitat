// Habitat Gamification, Progression, Streak & Achievement Engines
import 'dart:math';
import '../../../../database/local_database.dart';

class ProgressionEngine {
  int calculateTaskXp(LocalTask task, {double speedMultiplier = 1.0}) {
    int baseXp = switch (task.difficulty.toUpperCase()) {
      'HARD' => 50,
      'MEDIUM' => 25,
      _ => 10,
    };
    return (baseXp * speedMultiplier).round();
  }

  int calculateDailyBonus(int completed, int total) {
    if (total > 0 && completed >= total) {
      return 50; // Perfect day bonus XP
    }
    return 0;
  }

  int calculateLevel(int totalXp) {
    if (totalXp <= 0) return 1;
    return (sqrt(totalXp / 100)).floor() + 1;
  }

  String getDisciplineTitle(int level) {
    if (level >= 10) return 'Grandmaster of Discipline';
    if (level >= 7) return 'Master Practitioner';
    if (level >= 5) return 'Disciplined Veteran';
    if (level >= 3) return 'Dedicated Habitual';
    if (level >= 2) return 'Rising Explorer';
    return 'Explorer';
  }
}

class StreakCalculator {
  int calculateCurrentStreak(List<DateTime> completionDates) {
    if (completionDates.isEmpty) return 0;

    final normalized = completionDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (normalized.isEmpty ||
        (normalized.first != today && normalized.first != yesterday)) {
      return 0;
    }

    int streak = 1;
    for (int i = 0; i < normalized.length - 1; i++) {
      final current = normalized[i];
      final previous = normalized[i + 1];
      if (current.difference(previous).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}

class AchievementEvaluator {
  List<String> evaluateUnlockedAchievements({
    required int totalCompletedTasks,
    required int currentStreak,
    required int totalXp,
    required int totalWaterMl,
  }) {
    final unlocked = <String>[];

    if (totalCompletedTasks >= 1) unlocked.add('FIRST_STEP');
    if (totalCompletedTasks >= 10) unlocked.add('TEN_MISSIONS');
    if (totalCompletedTasks >= 100) unlocked.add('CENTURION_100');

    if (currentStreak >= 3) unlocked.add('STREAK_3_DAYS');
    if (currentStreak >= 7) unlocked.add('STREAK_7_DAYS');
    if (currentStreak >= 30) unlocked.add('STREAK_30_DAYS');

    if (totalWaterMl >= 2000) unlocked.add('HYDRATION_HERO');
    if (totalXp >= 500) unlocked.add('DISCIPLINE_ADEPT');

    return unlocked;
  }
}
