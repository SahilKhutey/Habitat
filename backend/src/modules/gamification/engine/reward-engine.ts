// Task Reward & Multiplier Engine

export class RewardEngine {
  /**
   * Calculates mission reward breakdown incorporating difficulty, attempt speed, and streak
   */
  public static calculateReward(params: {
    baseXp: number;
    difficulty: number;
    attemptCount: number;
    resistanceSeconds: number;
    currentStreak: number;
  }): {
    baseXp: number;
    difficultyMultiplier: number;
    speedBonus: number;
    streakBonus: number;
    totalXp: number;
  } {
    const diffMultiplier = 1.0 + (Math.max(1, params.difficulty) - 1) * 0.25; // 1.0x, 1.25x, 1.5x...
    const adjustedBase = Math.round(params.baseXp * diffMultiplier);

    // Speed bonus: first attempt within 120 seconds
    const resistanceMin = params.resistanceSeconds / 60.0;
    let speedBonus = 0;
    if (params.attemptCount === 1 && resistanceMin <= 2.0) {
      speedBonus = Math.round(adjustedBase * 0.5); // +50% Instant Action Bonus
    }

    // Streak bonus: +1 XP per 5 streak days (capped at +20 XP)
    const streakBonus = Math.min(20, Math.floor(params.currentStreak / 5));

    const totalXp = adjustedBase + speedBonus + streakBonus;

    return {
      baseXp: adjustedBase,
      difficultyMultiplier: diffMultiplier,
      speedBonus,
      streakBonus,
      totalXp
    };
  }
}
