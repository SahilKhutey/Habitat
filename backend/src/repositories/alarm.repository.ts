// Alarm Repository Interface & Implementation
import { DatabaseService } from '../db/connection';
import { v4 as uuidv4 } from 'uuid';

export interface AlarmEntity {
  id: string;
  userId: string;
  taskId: string;
  timeOfDay: string;
  timezone: string;
  repeatDays: number[];
  disciplineMode: 'GENTLE' | 'DISCIPLINE' | 'HARDCORE';
  retryIntervalMinutes: number;
  isEnabled: boolean;
  createdAt: string;
  updatedAt: string;
}

export class AlarmRepository {
  public static findByUserId(userId: string): AlarmEntity[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM alarms WHERE user_id = ? ORDER BY time_of_day ASC').all(userId) as any[];
    return rows.map(this.mapRow);
  }

  public static findById(id: string): AlarmEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM alarms WHERE id = ?').get(id) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public static create(params: {
    userId: string;
    taskId: string;
    timeOfDay: string;
    timezone?: string;
    repeatDays: number[];
    disciplineMode?: 'GENTLE' | 'DISCIPLINE' | 'HARDCORE';
    retryIntervalMinutes?: number;
  }): AlarmEntity {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    const formattedTime = params.timeOfDay.length === 5 ? `${params.timeOfDay}:00` : params.timeOfDay;

    db.prepare(`
      INSERT INTO alarms (id, user_id, task_id, time_of_day, timezone, repeat_days, discipline_mode, retry_interval_minutes, is_enabled, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
    `).run(
      id,
      params.userId,
      params.taskId,
      formattedTime,
      params.timezone || 'UTC',
      JSON.stringify(params.repeatDays),
      params.disciplineMode || 'DISCIPLINE',
      params.retryIntervalMinutes || 5,
      now,
      now
    );

    return this.findById(id)!;
  }

  private static mapRow(row: any): AlarmEntity {
    return {
      id: row.id,
      userId: row.user_id,
      taskId: row.task_id,
      timeOfDay: row.time_of_day,
      timezone: row.timezone,
      repeatDays: JSON.parse(row.repeat_days || '[]'),
      disciplineMode: row.discipline_mode,
      retryIntervalMinutes: row.retry_interval_minutes,
      isEnabled: Boolean(row.is_enabled),
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };
  }
}
