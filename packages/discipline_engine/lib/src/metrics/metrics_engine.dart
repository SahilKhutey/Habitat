// Metrics, XP Formulas, Resistance (ΔtR), and Streak Grace Engine
import '../models/alarm.dart';

class XpReward {
  final int totalXp;
  final double speedMultiplier;
  final double modeMultiplier;
  final bool isFirstAlarmBonus;
  final double resistanceMinutes;

  const XpReward({
    required this.totalXp,
    required this.speedMultiplier,
    required this.modeMultiplier,
    required this.isFirstAlarmBonus,
    required this.resistanceMinutes,
  });
}

class StreakEvaluationResult {
  final int newStreak;
  final int newGraceTokens;
  final bool usedGraceToken;
  final bool streakBroken;

  const StreakEvaluationResult({
    required this.newStreak,
    required this.newGraceTokens,
    required this.usedGraceToken,
    required this.streakBroken,
  });
}

class MetricsEngine {
  /// Resistance ΔtR = t_completed - t_scheduled (in seconds)
  static int calculateResistanceSeconds({
    required DateTime startTime,
    required DateTime completionTime,
  }) {
    final diff = completionTime.difference(startTime).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  /// Calculates XP earned with Speed & Strictness Multipliers
  static XpReward calculateXp({
    required int baseXp,
    required int resistanceSeconds,
    required int attemptCount,
    required DisciplineMode disciplineMode,
  }) {
    final resistanceMinutes = resistanceSeconds / 60.0;
    double speedMultiplier = 1.0;
    bool isFirstAlarmBonus = false;

    if (attemptCount == 1 && resistanceMinutes <= 2.0) {
      speedMultiplier = 1.5; // +50% Instant Action Bonus
      isFirstAlarmBonus = true;
    } else if (attemptCount == 1 && resistanceMinutes <= 5.0) {
      speedMultiplier = 1.0; // Nominal speed
      isFirstAlarmBonus = true;
    } else {
      // Procrastination retry penalty
      speedMultiplier = (1.0 - (attemptCount - 1) * 0.15).clamp(0.5, 1.0);
    }

    double modeMultiplier = switch (disciplineMode) {
      DisciplineMode.hardcore => 1.3,
      DisciplineMode.discipline => 1.0,
      DisciplineMode.gentle => 0.9,
    };

    final totalXp = (baseXp * speedMultiplier * modeMultiplier).round();

    return XpReward(
      totalXp: totalXp,
      speedMultiplier: speedMultiplier,
      modeMultiplier: modeMultiplier,
      isFirstAlarmBonus: isFirstAlarmBonus,
      resistanceMinutes: double.parse(resistanceMinutes.toStringAsFixed(2)),
    );
  }

  /// Evaluates Streak and Grace Token Vault
  static StreakEvaluationResult evaluateStreak({
    required int currentStreak,
    required int graceTokens,
    required bool missionSuccess,
  }) {
    if (missionSuccess) {
      final newStreak = currentStreak + 1;
      // Award 1 grace token every 14 days of consistency (max 3)
      final earnedGrace = (newStreak % 14 == 0) && (graceTokens < 3);
      return StreakEvaluationResult(
        newStreak: newStreak,
        newGraceTokens: earnedGrace ? graceTokens + 1 : graceTokens,
        usedGraceToken: false,
        streakBroken: false,
      );
    } else {
      if (graceTokens > 0) {
        // Protect streak using Grace Token
        return StreakEvaluationResult(
          newStreak: currentStreak,
          newGraceTokens: graceTokens - 1,
          usedGraceToken: true,
          streakBroken: false,
        );
      } else {
        // Streak Broken
        return const StreakEvaluationResult(
          newStreak: 0,
          newGraceTokens: 0,
          usedGraceToken: false,
          streakBroken: true,
        );
      }
    }
  }

  /// Autonomy Score (0 - 100): External -> Internal habit transition index
  static int calculateAutonomyScore({
    required double avgRecentResistanceMinutes,
    double baselineResistanceMinutes = 15.0,
  }) {
    if (baselineResistanceMinutes <= 0) return 100;
    final ratio = (avgRecentResistanceMinutes / baselineResistanceMinutes).clamp(0.0, 1.0);
    return ((1.0 - ratio) * 100).round();
  }
}
