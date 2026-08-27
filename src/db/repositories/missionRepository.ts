// Mission Repository (Stateful Execution Records)
import { DatabaseService } from '../connection';
import { Mission, MissionAttempt, MissionStatus } from '../../domain/types';
import { v4 as uuidv4 } from 'uuid';

export class MissionRepository {
  public static getById(id: string): Mission | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM missions WHERE id = ?').get(id) as any;
    if (!row) return null;
    return this.mapToMission(row);
  }

  public static getActiveMission(userId: string): Mission | null {
    const db = DatabaseService.getDb();
    const row = db.prepare(`
      SELECT * FROM missions 
      WHERE user_id = ? AND status IN ('TRIGGERED', 'IN_PROGRESS', 'PROOF_SUBMITTED', 'VERIFYING')
      ORDER BY scheduled_for DESC LIMIT 1
    `).get(userId) as any;
    if (!row) return null;
    return this.mapToMission(row);
  }

  public static getTodaysMissions(userId: string, dateStr: string): Mission[] {
    const db = DatabaseService.getDb();
    // Match date prefix (YYYY-MM-DD)
    const pattern = `${dateStr}%`;
    const rows = db.prepare(`
      SELECT * FROM missions 
      WHERE user_id = ? AND scheduled_for LIKE ?
      ORDER BY scheduled_for ASC
    `).all(userId, pattern) as any[];
    return rows.map(this.mapToMission);
  }

  public static getCompletedHistory(userId: string, limit: number = 30): Mission[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare(`
      SELECT * FROM missions 
      WHERE user_id = ? AND status = 'COMPLETED'
      ORDER BY completed_at DESC LIMIT ?
    `).all(userId, limit) as any[];
    return rows.map(this.mapToMission);
  }

  public static create(mission: Omit<Mission, 'id' | 'createdAt'>): Mission {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    const stmt = db.prepare(`
      INSERT INTO missions (id, user_id, alarm_id, task_id, scheduled_for, triggered_at, completed_at, status, attempts_count, resistance_seconds, xp_awarded, discipline_mode, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      id,
      mission.userId,
      mission.alarmId,
      mission.taskId,
      mission.scheduledFor,
      mission.triggeredAt,
      mission.completedAt,
      mission.status,
      mission.attemptsCount,
      mission.resistanceSeconds,
      mission.xpAwarded,
      mission.disciplineMode,
      now
    );

    return {
      ...mission,
      id,
      createdAt: now
    };
  }

  public static updateStatus(
    id: string,
    updates: {
      status?: MissionStatus;
      triggeredAt?: string;
      completedAt?: string;
      attemptsCount?: number;
      resistanceSeconds?: number;
      xpAwarded?: number;
    }
  ): Mission | null {
    const db = DatabaseService.getDb();
    const current = this.getById(id);
    if (!current) return null;

    const stmt = db.prepare(`
      UPDATE missions 
      SET status = ?, triggered_at = ?, completed_at = ?, attempts_count = ?, resistance_seconds = ?, xp_awarded = ?
      WHERE id = ?
    `);

    stmt.run(
      updates.status ?? current.status,
      updates.triggeredAt ?? current.triggeredAt,
      updates.completedAt ?? current.completedAt,
      updates.attemptsCount ?? current.attemptsCount,
      updates.resistanceSeconds ?? current.resistanceSeconds,
      updates.xpAwarded ?? current.xpAwarded,
      id
    );

    return this.getById(id);
  }

  // Attempt tracking
  public static addAttempt(missionId: string, attemptIndex: number, sirenVolumeLevel: number): MissionAttempt {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    const stmt = db.prepare(`
      INSERT INTO mission_attempts (id, mission_id, attempt_index, triggered_at, status, siren_volume_level)
      VALUES (?, ?, ?, ?, 'IGNORED', ?)
    `);

    stmt.run(id, missionId, attemptIndex, now, sirenVolumeLevel);

    return {
      id,
      missionId,
      attemptIndex,
      triggeredAt: now,
      resolvedAt: null,
      status: 'IGNORED',
      sirenVolumeLevel
    };
  }

  public static resolveAttempt(attemptId: string, status: 'PASSED' | 'FAILED'): void {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    const stmt = db.prepare('UPDATE mission_attempts SET status = ?, resolved_at = ? WHERE id = ?');
    stmt.run(status, now, attemptId);
  }

  public static getAttempts(missionId: string): MissionAttempt[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM mission_attempts WHERE mission_id = ? ORDER BY attempt_index ASC').all(missionId) as any[];
    return rows.map((r) => ({
      id: r.id,
      missionId: r.mission_id,
      attemptIndex: r.attempt_index,
      triggeredAt: r.triggered_at,
      resolvedAt: r.resolved_at,
      status: r.status,
      sirenVolumeLevel: r.siren_volume_level
    }));
  }

  private static mapToMission(row: any): Mission {
    return {
      id: row.id,
      userId: row.user_id,
      alarmId: row.alarm_id,
      taskId: row.task_id,
      scheduledFor: row.scheduled_for,
      triggeredAt: row.triggered_at,
      completedAt: row.completed_at,
      status: row.status as MissionStatus,
      attemptsCount: row.attempts_count,
      resistanceSeconds: row.resistance_seconds,
      xpAwarded: row.xp_awarded,
      disciplineMode: row.discipline_mode,
      createdAt: row.created_at
    };
  }
}
