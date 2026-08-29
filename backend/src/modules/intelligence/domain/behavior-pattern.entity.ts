// Behavior Pattern Domain Entity

export type PatternClassification = 'OBSERVED' | 'LIKELY' | 'POSSIBLE' | 'INSUFFICIENT_DATA';

export interface BehaviorPatternEntity {
  id: string;
  userId: string;
  patternType: string;
  confidence: number; // 0.0 - 1.0
  sampleSize: number;
  periodDays: number;
  evidence: string[];
  classification: PatternClassification;
  createdAt: Date;
}
