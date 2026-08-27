// Task Performance & Behavior Pattern Domain Entities

export type DifficultyClassification =
  | 'TOO_EASY'
  | 'EASY'
  | 'BALANCED'
  | 'CHALLENGING'
  | 'TOO_HARD'
  | 'UNKNOWN';

export interface TaskPerformanceEntity {
  id: string;
  userId: string;
  taskTemplateId: string;
  taskName?: string;
  periodStart: Date;
  periodEnd: Date;
  attempts: number;
  completions: number;
  misses: number;
  averageDelaySec: number;
  averageDurationSec: number;
  successRate: number; // 0.0 - 100.0%
  difficultyScore: number; // 0.0 - 1.0
  difficultyLevel: DifficultyClassification;
  createdAt: Date;
  updatedAt: Date;
}

export interface TimePerformance {
  hour: number; // 0 - 23
  attempts: number;
  completions: number;
  successRate: number; // 0.0 - 100.0%
}

export interface DayPerformance {
  dayOfWeek: number; // 1 (Mon) - 7 (Sun)
  dayName: string;
  attempts: number;
  completions: number;
  successRate: number;
}

export interface BehaviorPatternEntity {
  userId: string;
  strongestWindow?: { startHour: number; endHour: number; successRate: number };
  weakestDays?: string[];
  averageDelayMinutes: number;
  routineHealth: 'EXCELLENT' | 'GOOD' | 'NEEDS_ATTENTION' | 'OVERLOADED';
}
