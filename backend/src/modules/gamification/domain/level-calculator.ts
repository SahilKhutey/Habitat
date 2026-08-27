// Authoritative Level Progression Curve & Discipline Score Calculator

export class LevelCalculator {
  /**
   * Computes user level, current level XP bucket, and progress to next level
   * Base formula: XP Threshold for Level L = 50 * (L - 1) * L
   * L1 = 0, L2 = 100, L3 = 300, L4 = 600, L5 = 1000, L6 = 1500, etc.
   */
  public static calculateLevel(totalXp: number): {
    level: number;
    currentLevelBaseXp: number;
    nextLevelBaseXp: number;
    xpIntoCurrentLevel: number;
    xpNeededForNextLevel: number;
    progressPercent: number;
  } {
    let level = 1;
    while (true) {
      const nextThreshold = 50 * level * (level + 1);
      if (totalXp < nextThreshold) {
        break;
      }
      level++;
    }

    const currentLevelBaseXp = 50 * (level - 1) * level;
    const nextLevelBaseXp = 50 * level * (level + 1);
    const xpIntoCurrentLevel = Math.max(0, totalXp - currentLevelBaseXp);
    const xpNeededForNextLevel = Math.max(1, nextLevelBaseXp - currentLevelBaseXp);
    const progressPercent = Math.min(100, Math.round((xpIntoCurrentLevel / xpNeededForNextLevel) * 100));

    return {
      level,
      currentLevelBaseXp,
      nextLevelBaseXp,
      xpIntoCurrentLevel,
      xpNeededForNextLevel,
      progressPercent
    };
  }

  /**
   * Computes 0-100 Daily Discipline Score
   */
  public static calculateDailyDisciplineScore(params: {
    scheduledCount: number;
    completedCount: number;
    firstAttemptCount: number;
    speedBonusCount: number;
  }): number {
    if (params.scheduledCount <= 0) return 100;

    const completionRate = Math.min(1.0, params.completedCount / params.scheduledCount);
    const firstAttemptRate = params.completedCount > 0
      ? Math.min(1.0, params.firstAttemptCount / params.completedCount)
      : 0;
    const speedBonusRate = params.completedCount > 0
      ? Math.min(1.0, params.speedBonusCount / params.completedCount)
      : 0;

    const score = Math.round(
      100 * (0.5 * completionRate + 0.3 * firstAttemptRate + 0.2 * speedBonusRate)
    );

    return Math.max(0, Math.min(100, score));
  }
}
