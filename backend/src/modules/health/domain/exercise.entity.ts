// Exercise Domain Entities, Categories, Units & Sessions

export type ExerciseCategory =
  | 'STRENGTH'
  | 'CARDIO'
  | 'MOBILITY'
  | 'FLEXIBILITY'
  | 'BALANCE'
  | 'SPORT'
  | 'WALKING'
  | 'RUNNING'
  | 'OTHER';

export type ExerciseUnit =
  | 'REPETITIONS'
  | 'SECONDS'
  | 'MINUTES'
  | 'METERS'
  | 'KILOMETERS'
  | 'CALORIES'
  | 'SETS'
  | 'DISTANCE';

export type ExerciseSource = 'APP' | 'APPLE_HEALTH' | 'HEALTH_CONNECT' | 'MANUAL' | 'IMPORTED';

export interface ExerciseTemplateEntity {
  id: string;
  name: string;
  category: ExerciseCategory;
  description?: string;
  unit: ExerciseUnit;
  difficulty?: string;
  active: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface ExerciseSessionEntity {
  id: string;
  userId: string;
  exerciseId: string;
  exerciseName?: string;
  startedAt: Date;
  endedAt?: Date;
  durationSec: number;
  quantity?: number;
  unit: ExerciseUnit;
  sets?: number;
  notes?: string;
  source: ExerciseSource;
  externalId?: string;
  createdAt: Date;
}
