// Alarm Occurrence Lifecycle & Audit Log Domain Models

export type OccurrenceStatus = 'SCHEDULED' | 'TRIGGERED' | 'RETRYING' | 'DISARMED' | 'MISSED' | 'CANCELLED';

export interface AlarmOccurrence {
  occurrenceId: string;
  alarmId: string;
  missionId: string;
  userId: string;
  scheduledAt: string;
  schedulerRegisteredAt: string;
  triggeredAt?: string | null;
  missionStartedAt?: string | null;
  completedAt?: string | null;
  retryCount: number;
  failureReason?: string | null;
  platform: 'android' | 'ios' | 'web';
  status: OccurrenceStatus;
  createdAt: string;
  updatedAt?: string | null;
}
