// Mission & Attempt Repository Interface & Implementation
import { DatabaseService } from '../db/connection';
import { v4 as uuidv4 } from 'uuid';

export interface MissionEntity {
  id: string;
  userId: string;
  alarmId: string | null;
  taskId: string;
  scheduledAt: string;
  triggeredAt: string | null;
  completedAt: string | null;
  status: string;
  attemptCount: number;
  resistanceSeconds: number | null;
  disciplineMode: string;
  idempotencyKey: string | null;
  createdAt: string;
}

export class MissionRepository {
  public static findById(id: string): MissionEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM missions WHERE id = ?').get(id) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public static findByIdempotencyKey(key: string): MissionEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM missions WHERE idempotency_key = ?').get(key) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public static create(params: {
    userId: string;
    taskId: string;
    alarmId?: string;
    scheduledAt?: string;
    disciplineMode?: string;
    idempotencyKey?: string;
  }): MissionEntity {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();
    const scheduled = params.scheduledAt || now;

    db.prepare(`
      INSERT INTO missions (id, user_id, alarm_id, task_id, scheduled_at, triggered_at, status, attempt_count, discipline_mode, idempotency_key, created_at)
      VALUES (?, ?, ?, ?, ?, ?, 'TRIGGERED', 1, ?, ?, ?)
    `).run(
      id,
      params.userId,
      params.alarmId || null,
      params.taskId,
      scheduled,
      now,
      params.disciplineMode || 'DISCIPLINE',
      params.idempotencyKey || null,
      now
    );

    // Initial attempt #1
    db.prepare(`
      INSERT INTO mission_attempts (id, mission_id, attempt_index, triggered_at, status, siren_volume_level)
      VALUES (?, ?, 1, ?, 'IGNORED', 70)
    `).run(uuidv4(), id, now);

    return this.findById(id)!;
  }

  public static updateStatus(id: string, status: string, completedAt?: string, resistanceSeconds?: number): void {
    const db = DatabaseService.getDb();
    db.prepare(`
      UPDATE missions 
      SET status = ?, completed_at = COALESCE(?, completed_at), resistance_seconds = COALESCE(?, resistance_seconds)
      WHERE id = ?
    `).run(status, completedAt || null, resistanceSeconds ?? null, id);
  }

  private static mapRow(row: any): MissionEntity {
    return {
      id: row.id,
      userId: row.user_id,
      alarmId: row.alarm_id,
      taskId: row.task_id,
      scheduledAt: row.scheduled_at,
      triggeredAt: row.triggered_at,
      completedAt: row.completed_at,
      status: row.status,
      attemptCount: row.attempt_count,
      resistanceSeconds: row.resistance_seconds,
      disciplineMode: row.discipline_mode,
      idempotencyKey: row.idempotency_key,
      createdAt: row.created_at
    };
  }
}
