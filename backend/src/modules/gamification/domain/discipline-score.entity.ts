// Discipline Score Domain Entity

export interface DisciplineScoreEntity {
  userId: string;
  score: number;
  completionRate: number;
  consistencyRate: number;
  difficultyFactor: number;
  streakFactor: number;
  rollingWindowDays: number;
}
