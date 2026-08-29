// Alarm Occurrence Repository for Audit Trail & Reliability Observability
import { DatabaseService } from '../db/connection';
import { AlarmOccurrence, OccurrenceStatus } from '../modules/alarms/domain/alarm-occurrence.types';
import { v4 as uuidv4 } from 'uuid';

export class AlarmOccurrenceRepository {
  public static create(params: {
    occurrenceId?: string;
    alarmId: string;
    missionId: string;
    userId: string;
    scheduledAt: string;
    platform?: 'android' | 'ios' | 'web';
  }): AlarmOccurrence {
    const db = DatabaseService.getDb();
    const occurrenceId = params.occurrenceId || `occ_${uuidv4().replace(/-/g, '')}`;
    const now = new Date().toISOString();
    const platform = params.platform || 'android';

    db.prepare(`
      INSERT INTO alarm_occurrences (
        occurrence_id, alarm_id, mission_id, user_id, scheduled_at,
        scheduler_registered_at, triggered_at, mission_started_at, completed_at,
        retry_count, failure_reason, platform, status, created_at, updated_at
      ) VALUES (
        ?, ?, ?, ?, ?,
        ?, NULL, NULL, NULL,
        0, NULL, ?, 'SCHEDULED', ?, ?
      )
    `).run(
      occurrenceId,
      params.alarmId,
      params.missionId,
      params.userId,
      params.scheduledAt,
      now,
      platform,
      now,
      now
    );

    return this.findById(occurrenceId)!;
  }

  public static findById(occurrenceId: string): AlarmOccurrence | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM alarm_occurrences WHERE occurrence_id = ?').get(occurrenceId) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public static findByAlarmId(alarmId: string): AlarmOccurrence[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM alarm_occurrences WHERE alarm_id = ? ORDER BY scheduled_at DESC').all(alarmId) as any[];
    return rows.map((r) => this.mapRow(r));
  }

  public static findByMissionId(missionId: string): AlarmOccurrence | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM alarm_occurrences WHERE mission_id = ?').get(missionId) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public static markTriggered(occurrenceId: string): void {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    db.prepare(`
      UPDATE alarm_occurrences SET
        triggered_at = ?,
        status = 'TRIGGERED',
        updated_at = ?
      WHERE occurrence_id = ?
    `).run(now, now, occurrenceId);
  }

  public static markMissionStarted(occurrenceId: string): void {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    db.prepare(`
      UPDATE alarm_occurrences SET
        mission_started_at = ?,
        updated_at = ?
      WHERE occurrence_id = ?
    `).run(now, now, occurrenceId);
  }

  public static incrementRetry(occurrenceId: string): void {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    db.prepare(`
      UPDATE alarm_occurrences SET
        retry_count = retry_count + 1,
        status = 'RETRYING',
        updated_at = ?
      WHERE occurrence_id = ?
    `).run(now, occurrenceId);
  }

  public static markDisarmed(occurrenceId: string, completedAt?: string): void {
    const db = DatabaseService.getDb();
    const now = completedAt || new Date().toISOString();
    db.prepare(`
      UPDATE alarm_occurrences SET
        completed_at = ?,
        status = 'DISARMED',
        updated_at = ?
      WHERE occurrence_id = ?
    `).run(now, now, occurrenceId);
  }

  public static markMissed(occurrenceId: string, reason: string): void {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    db.prepare(`
      UPDATE alarm_occurrences SET
        failure_reason = ?,
        status = 'MISSED',
        updated_at = ?
      WHERE occurrence_id = ?
    `).run(reason, now, occurrenceId);
  }

  private static mapRow(row: any): AlarmOccurrence {
    return {
      occurrenceId: row.occurrence_id,
      alarmId: row.alarm_id,
      missionId: row.mission_id,
      userId: row.user_id,
      scheduledAt: row.scheduled_at,
      schedulerRegisteredAt: row.scheduler_registered_at,
      triggeredAt: row.triggered_at,
      missionStartedAt: row.mission_started_at,
      completedAt: row.completed_at,
      retryCount: row.retry_count,
      failureReason: row.failure_reason,
      platform: row.platform,
      status: row.status as OccurrenceStatus,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };
  }
}
