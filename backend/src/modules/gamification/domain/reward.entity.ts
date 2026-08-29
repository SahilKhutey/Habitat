// Gamification Reward Domain Entity
export interface RewardCalculationParams {
  baseXp: number;
  difficulty: number;
  attemptCount?: number;
  resistanceSeconds?: number;
  currentStreak?: number;
}

export interface RewardBreakdown {
  baseXp: number;
  difficultyMultiplier: number;
  speedBonus: number;
  streakBonus: number;
  totalXp: number;
}
