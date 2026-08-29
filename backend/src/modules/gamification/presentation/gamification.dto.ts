// Gamification Presentation DTOs & Validation Schemas
export interface AwardXpDto {
  userId: string;
  amount: number;
  sourceType: string;
  sourceId?: string;
  reason: string;
  idempotencyKey?: string;
}

export interface GamificationProfileDto {
  level: number;
  currentXp: number;
  xpToNextLevel: number;
  levelProgress: number;
  currentStreak: number;
  bestStreak: number;
  graceTokens: number;
  disciplineScore: number;
  totalMissionsCompleted: number;
  unlockedAchievementsCount: number;
}
