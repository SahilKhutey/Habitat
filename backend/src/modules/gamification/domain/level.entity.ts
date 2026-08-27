// Level Progress & Streak Domain Entities

export interface LevelProgressEntity {
  level: number;
  totalXp: number;
  currentLevelBaseXp: number;
  nextLevelBaseXp: number;
  xpIntoCurrentLevel: number;
  xpNeededForNextLevel: number;
  progressPercent: number;
}

export interface StreakEntity {
  userId: string;
  currentStreak: number;
  bestStreak: number;
  graceTokens: number;
  lastQualifiedDate?: string;
  recoveryUsed: boolean;
  updatedAt: Date;
}
