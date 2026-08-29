// Daily Plan, AI Action, and Coach Session Domain Entities

export interface DailyScheduleItem {
  id: string;
  time: string; // "07:00"
  title: string;
  category: 'DISCIPLINE' | 'EXERCISE' | 'HYDRATION' | 'WELLNESS' | 'WORK' | 'WIND_DOWN';
  durationMinutes: number;
  isFixed: boolean;
  isCompleted: boolean;
  priority: number; // 1-7
}

export interface ScheduleConflict {
  itemA: string;
  itemB: string;
  overlapMinutes: number;
  suggestedResolution: string;
}

export interface DailyPlanEntity {
  id: string;
  userId: string;
  planDate: string; // "YYYY-MM-DD"
  scheduleItems: DailyScheduleItem[];
  conflicts: ScheduleConflict[];
  status: 'PROPOSED' | 'APPROVED' | 'COMPLETED' | 'MODIFIED';
  createdAt: Date;
  updatedAt: Date;
}

export type AIActionType =
  | 'PROPOSE_TASK'
  | 'PROPOSE_SCHEDULE_CHANGE'
  | 'PROPOSE_GOAL_CHANGE'
  | 'PROPOSE_RECOVERY'
  | 'PROPOSE_ROUTINE_CHANGE'
  | 'SHOW_INSIGHT'
  | 'SHOW_PLAN';

export interface DisciplineAIAction {
  id: string;
  type: AIActionType;
  title: string;
  message: string;
  evidence: string[];
  confidence: number;
  payload?: any;
  status: 'PENDING_APPROVAL' | 'APPROVED' | 'REJECTED' | 'EXPIRED';
  createdAt: Date;
}

export interface CoachSessionEntity {
  id: string;
  userId: string;
  startedAt: Date;
  endedAt?: Date;
  summary?: string;
  metadata?: any;
  createdAt: Date;
}

export interface CoachMessageEntity {
  id: string;
  sessionId: string;
  userId: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  metadata?: any;
  createdAt: Date;
}
