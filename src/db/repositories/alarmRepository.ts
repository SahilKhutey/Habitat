// Alarm Repository (Mission Rules & Commitments)
import { DatabaseService } from '../connection';
import { Alarm } from '../../domain/types';
import { v4 as uuidv4 } from 'uuid';

export class AlarmRepository {
  public static getAllByUser(userId: string): Alarm[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM alarms WHERE user_id = ? ORDER BY time_of_day ASC').all(userId) as any[];
    return rows.map(this.mapToAlarm);
  }

  public static getActiveAlarms(): Alarm[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM alarms WHERE is_active = 1').all() as any[];
    return rows.map(this.mapToAlarm);
  }

  public static getById(id: string): Alarm | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM alarms WHERE id = ?').get(id) as any;
    if (!row) return null;
    return this.mapToAlarm(row);
  }

  public static create(alarm: Omit<Alarm, 'id' | 'createdAt' | 'updatedAt'>): Alarm {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    const stmt = db.prepare(`
      INSERT INTO alarms (id, user_id, task_id, time_of_day, repeat_days, discipline_mode, retry_interval_minutes, escalation_enabled, sound_pack, is_active, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      id,
      alarm.userId,
      alarm.taskId,
      alarm.timeOfDay,
      JSON.stringify(alarm.repeatDays),
      alarm.disciplineMode,
      alarm.retryIntervalMinutes,
      alarm.escalationEnabled ? 1 : 0,
      alarm.soundPack,
      alarm.isActive ? 1 : 0,
      now,
      now
    );

    return {
      ...alarm,
      id,
      createdAt: now,
      updatedAt: now
    };
  }

  public static update(id: string, updates: Partial<Omit<Alarm, 'id' | 'userId' | 'createdAt'>>): Alarm | null {
    const db = DatabaseService.getDb();
    const current = this.getById(id);
    if (!current) return null;

    const now = new Date().toISOString();
    const updated: Alarm = {
      ...current,
      ...updates,
      updatedAt: now
    };

    const stmt = db.prepare(`
      UPDATE alarms 
      SET task_id = ?, time_of_day = ?, repeat_days = ?, discipline_mode = ?, retry_interval_minutes = ?, escalation_enabled = ?, sound_pack = ?, is_active = ?, updated_at = ?
      WHERE id = ?
    `);

    stmt.run(
      updated.taskId,
      updated.timeOfDay,
      JSON.stringify(updated.repeatDays),
      updated.disciplineMode,
      updated.retryIntervalMinutes,
      updated.escalationEnabled ? 1 : 0,
      updated.soundPack,
      updated.isActive ? 1 : 0,
      now,
      id
    );

    return updated;
  }

  public static delete(id: string): boolean {
    const db = DatabaseService.getDb();
    const stmt = db.prepare('DELETE FROM alarms WHERE id = ?');
    stmt.run(id);
    return true;
  }

  private static mapToAlarm(row: any): Alarm {
    return {
      id: row.id,
      userId: row.user_id,
      taskId: row.task_id,
      timeOfDay: row.time_of_day,
      repeatDays: JSON.parse(row.repeat_days || '[]'),
      disciplineMode: row.discipline_mode,
      retryIntervalMinutes: row.retry_interval_minutes,
      escalationEnabled: Boolean(row.escalation_enabled),
      soundPack: row.sound_pack,
      isActive: Boolean(row.is_active),
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };
  }
}
