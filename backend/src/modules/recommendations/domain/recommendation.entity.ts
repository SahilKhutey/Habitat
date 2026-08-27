// Recommendation Domain Entity & Lifecycle States

export type RecommendationType =
  | 'MOVE_TASK'
  | 'REDUCE_DIFFICULTY'
  | 'INCREASE_DIFFICULTY'
  | 'SIMPLIFY_ROUTINE'
  | 'ADD_REST'
  | 'RESCHEDULE'
  | 'MAINTAIN'
  | 'RECOVER'
  | 'NEW_TASK';

export type RecommendationStatus =
  | 'PENDING'
  | 'VIEWED'
  | 'ACCEPTED'
  | 'DECLINED'
  | 'EXPIRED'
  | 'DISMISSED';

export type RecommendationPriority = 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT';

export interface RecommendationEntity {
  id: string;
  userId: string;
  type: RecommendationType;
  priority: RecommendationPriority;
  confidence: number; // 0.0 - 1.0 (e.g. 0.88)
  title: string;
  explanation: string;
  payload?: {
    taskTemplateId?: string;
    routineId?: string;
    proposedDifficulty?: number;
    proposedTime?: string;
    currentSchedule?: string;
    recoveryPlan?: any;
    [key: string]: any;
  };
  status: RecommendationStatus;
  createdAt: Date;
  expiresAt?: Date;
  resolvedAt?: Date;
}
