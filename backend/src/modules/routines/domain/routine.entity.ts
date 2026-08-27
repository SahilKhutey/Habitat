// Routine Domain Entity & Status Enums
import { RoutineTaskEntity } from './routine-task.entity';
import { ScheduleRuleEntity } from './schedule-rule.entity';

export type RoutineType = 'MORNING' | 'EVENING' | 'EXERCISE' | 'STUDY' | 'WORK' | 'HEALTH' | 'CUSTOM';
export type RoutineStatus = 'DRAFT' | 'ACTIVE' | 'PAUSED' | 'ARCHIVED';

export interface RoutineEntity {
  id: string;
  userId: string;
  name: string;
  description?: string;
  type: RoutineType;
  status: RoutineStatus;
  version: number;
  pauseUntil?: string;
  minimumRequiredTasks: number;
  tasks?: RoutineTaskEntity[];
  schedule?: ScheduleRuleEntity;
  createdAt: Date;
  updatedAt: Date;
}
