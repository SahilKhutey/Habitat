// Behavior Pattern Domain Entity
export type PatternType =
  | 'MORNING_STRENGTH'
  | 'EVENING_FRICTION'
  | 'WEEKEND_LAPSE'
  | 'TIME_DRIFT'
  | 'DURATION_FATIGUE'
  | 'STABLE_CONSISTENCY';

export interface BehaviorPatternEntity {
  id: string;
  userId: string;
  patternType: PatternType;
  confidence: number;
  sampleSize: number;
  periodDays: number;
  evidence: string[];
  classification: 'OBSERVED' | 'LIKELY' | 'POSSIBLE' | 'INSUFFICIENT_DATA';
  createdAt: Date;
}
