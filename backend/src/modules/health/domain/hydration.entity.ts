// Hydration, Sleep, Wellness Goal & Provider Domain Entities

export interface HydrationEntryEntity {
  id: string;
  userId: string;
  amountMl: number;
  timestamp: Date;
  source: string;
  externalId?: string;
  createdAt: Date;
}

export interface SleepSessionEntity {
  id: string;
  userId: string;
  startedAt: Date;
  endedAt: Date;
  durationSec: number;
  source: string;
  quality?: number; // 1-100 or 1-5
  notes?: string;
  externalId?: string;
  createdAt: Date;
}

export type WellnessGoalType = 'MOVEMENT' | 'EXERCISE' | 'HYDRATION' | 'SLEEP' | 'CUSTOM';

export interface WellnessGoalEntity {
  id: string;
  userId: string;
  type: WellnessGoalType;
  target: number;
  unit: string;
  startDate: Date;
  endDate?: Date;
  status: 'ACTIVE' | 'PAUSED' | 'COMPLETED' | 'CANCELLED';
  createdAt: Date;
  updatedAt: Date;
}

export interface HealthProviderConnectionEntity {
  id: string;
  userId: string;
  provider: 'APPLE_HEALTH' | 'HEALTH_CONNECT' | 'MANUAL';
  status: 'CONNECTED' | 'DISCONNECTED' | 'REVOKED';
  permissions: {
    exercise: boolean;
    steps: boolean;
    sleep: boolean;
    heartRate: boolean;
  };
  lastSyncAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}
