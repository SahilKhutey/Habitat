// Declarative Achievement & Discipline Score Domain Entities

export type AchievementRequirementType =
  | 'STREAK'
  | 'MISSION_COUNT'
  | 'XP_TOTAL'
  | 'EARLY_RISER'
  | 'SPEED_BONUS_COUNT'
  | 'DIFFICULTY_HARD';

export interface AchievementRequirement {
  type: AchievementRequirementType;
  value: number;
}

export interface AchievementEntity {
  id: string;
  code: string;
  name: string;
  description: string;
  requirement: AchievementRequirement;
  xpReward: number;
  active: boolean;
  unlockedAt?: string;
  isUnlocked?: boolean;
}

export interface DisciplineScoreEntity {
  userId: string;
  score: number;
  completionRate: number;
  consistencyRate: number;
  difficultyFactor: number;
  streakFactor: number;
  rollingWindowDays: number;
}
