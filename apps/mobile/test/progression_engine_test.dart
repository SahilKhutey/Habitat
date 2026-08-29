// Habitat Progression, Streak & Achievement Engine Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/gamification/domain/services/progression_engine.dart';

void main() {
  late ProgressionEngine progressionEngine;
  late StreakCalculator streakCalculator;
  late AchievementEvaluator achievementEvaluator;

  setUp(() {
    progressionEngine = ProgressionEngine();
    streakCalculator = StreakCalculator();
    achievementEvaluator = AchievementEvaluator();
  });

  group('ProgressionEngine Unit Tests', () {
    test('calculateTaskXp() scales XP with difficulty and speed bonus', () {
      final hardTask = LocalTask(
        id: '1',
        title: 'Cold Shower',
        category: 'PHYSICAL',
        difficulty: 'HARD',
        taskType: 'TIMER',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final xpStandard = progressionEngine.calculateTaskXp(hardTask);
      expect(xpStandard, equals(50));

      final xpBonus = progressionEngine.calculateTaskXp(hardTask, speedMultiplier: 1.5);
      expect(xpBonus, equals(75));
    });

    test('calculateLevel() maps XP to user level correctly', () {
      expect(progressionEngine.calculateLevel(0), equals(1));
      expect(progressionEngine.calculateLevel(100), equals(2));
      expect(progressionEngine.calculateLevel(400), equals(3));
      expect(progressionEngine.calculateLevel(900), equals(4));
    });
  });

  group('StreakCalculator Unit Tests', () {
    test('calculateCurrentStreak() counts consecutive daily discipline dates', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      final streak = streakCalculator.calculateCurrentStreak([today, yesterday, twoDaysAgo]);
      expect(streak, equals(3));
    });

    test('calculateCurrentStreak() returns 0 when broken', () {
      final fourDaysAgo = DateTime.now().subtract(const Duration(days: 4));
      final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));

      final streak = streakCalculator.calculateCurrentStreak([fourDaysAgo, fiveDaysAgo]);
      expect(streak, equals(0));
    });
  });

  group('AchievementEvaluator Unit Tests', () {
    test('evaluateUnlockedAchievements() unlocks achievements upon milestone completion', () {
      final unlocked = achievementEvaluator.evaluateUnlockedAchievements(
        totalCompletedTasks: 10,
        currentStreak: 7,
        totalXp: 600,
        totalWaterMl: 2500,
      );

      expect(unlocked, contains('FIRST_STEP'));
      expect(unlocked, contains('TEN_MISSIONS'));
      expect(unlocked, contains('STREAK_7_DAYS'));
      expect(unlocked, contains('HYDRATION_HERO'));
      expect(unlocked, contains('DISCIPLINE_ADEPT'));
    });
  });
}
