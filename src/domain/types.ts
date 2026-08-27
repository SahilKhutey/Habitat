// Habitat Core Domain Types & Entity Models

export type DisciplineMode = 'GENTLE' | 'DISCIPLINE' | 'HARDCORE';

export type TaskCategory = 'exercise' | 'hygiene' | 'environment' | 'health' | 'mindset' | 'routine';

export type ProofType = 'PHOTO' | 'VIDEO' | 'SENSOR';

export type VerificationLevel = 'HEURISTIC' | 'SMART_CV' | 'AI_ACTION';

export type MissionStatus = 
  | 'SCHEDULED'
  | 'TRIGGERED'
  | 'IN_PROGRESS'
  | 'PROOF_SUBMITTED'
  | 'VERIFYING'
  | 'COMPLETED'
  | 'FAILED';

export type AttemptStatus = 'IGNORED' | 'FAILED' | 'PASSED';

export type VerificationStatus = 'PENDING' | 'ACCEPTED' | 'REJECTED';

// User Entity
export interface User {
  id: string;
  email: string;
  displayName: string;
  timezone: string;
  disciplineScore: number; // 0 - 100
  autonomyLevel: 1 | 2 | 3 | 4 | 5;
  currentStreak: number;
  longestStreak: number;
  totalXp: number;
  graceTokens: number;
  createdAt: string;
  updatedAt: string;
}

// Task Definition Blueprint
export interface Task {
  id: string;
  slug: string;
  title: string;
  description: string;
  category: TaskCategory;
  proofType: ProofType;
  verificationLevel: VerificationLevel;
  baseXp: number;
  instructions: string[];
  validationRules: {
    minLuminance?: number;
    requiredLabels?: string[];
    minDurationSec?: number;
    motionThreshold?: number;
    skyRatioMin?: number;
  };
  isStarter: boolean;
  createdAt: string;
}

// Scheduled Alarm Contract
export interface Alarm {
  id: string;
  userId: string;
  taskId: string;
  timeOfDay: string; // 'HH:MM:SS'
  repeatDays: number[]; // [0,1,2,3,4,5,6] (0=Sun, 6=Sat)
  disciplineMode: DisciplineMode;
  retryIntervalMinutes: number;
  escalationEnabled: boolean;
  soundPack: 'TACTICAL_SIREN' | 'ZEN_BELLS' | 'PULSE' | 'MILITARY_BUGLE';
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

// Active Mission Execution Instance
export interface Mission {
  id: string;
  userId: string;
  alarmId: string | null;
  taskId: string;
  scheduledFor: string;
  triggeredAt: string | null;
  completedAt: string | null;
  status: MissionStatus;
  attemptsCount: number;
  resistanceSeconds: number | null;
  xpAwarded: number;
  disciplineMode: DisciplineMode;
  createdAt: string;
}

// Individual Escalation Attempt
export interface MissionAttempt {
  id: string;
  missionId: string;
  attemptIndex: number;
  triggeredAt: string;
  resolvedAt: string | null;
  status: AttemptStatus;
  sirenVolumeLevel: number; // 0 - 100
}

// Proof Asset & Sensor Metadata
export interface ProofAsset {
  id: string;
  missionId: string;
  mediaType: 'image/jpeg' | 'video/mp4';
  storageUrl: string;
  thumbnailUrl: string | null;
  capturedAt: string;
  deviceMetadata: {
    ambientLux?: number;
    accelerometerMotion?: boolean;
    appVersion?: string;
    clientTimestamp?: number;
  };
  verificationStatus: VerificationStatus;
  aiConfidenceScore?: number;
  rejectionReason?: string;
  createdAt: string;
}

// Resistance & Progression Summary
export interface DisciplineMetrics {
  disciplineScore: number;
  currentStreak: number;
  longestStreak: number;
  totalXp: number;
  graceTokens: number;
  autonomyScore: number;
  averageResistanceMinutes: number;
  totalMissionsCompleted: number;
  completionRate7d: number; // percentage
  resistanceHistory7d: {
    date: string;
    resistanceMinutes: number;
    attempts: number;
    completed: boolean;
  }[];
}
