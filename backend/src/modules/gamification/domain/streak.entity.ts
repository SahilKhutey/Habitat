// Streak Domain Entity

export interface StreakEntity {
  userId: string;
  currentStreak: number;
  bestStreak: number;
  graceTokens: number;
  lastQualifiedDate?: string;
  recoveryUsed: boolean;
  updatedAt: Date;
}
