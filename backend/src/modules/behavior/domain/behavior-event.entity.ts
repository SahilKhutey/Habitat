// Behavior Event Entity & Canonical Event Types

export type BehaviorEventType =
  | 'mission.created'
  | 'mission.triggered'
  | 'mission.started'
  | 'mission.completed'
  | 'mission.missed'
  | 'mission.snoozed'
  | 'mission.rescheduled'
  | 'proof.submitted'
  | 'proof.accepted'
  | 'proof.rejected'
  | 'routine.completed'
  | 'routine.partially_completed'
  | 'routine.skipped'
  | 'alarm.dismissed'
  | 'alarm.repeated'
  | 'task.abandoned';

export interface BehaviorEventEntity {
  id: string;
  userId: string;
  type: BehaviorEventType | string;
  missionId?: string;
  taskId?: string;
  routineId?: string;
  timestamp: Date;
  metadata?: Record<string, any>;
  idempotencyKey?: string;
  createdAt: Date;
}
