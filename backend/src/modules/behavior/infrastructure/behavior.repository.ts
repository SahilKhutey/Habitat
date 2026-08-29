// Behavior Infrastructure Repository
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';

export class BehaviorRepository {
  public static recordEvent(event: {
    userId: string;
    type: string;
    missionId?: string;
    taskId?: string;
    routineId?: string;
    metadata?: any;
  }): void {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO behavior_events (id, user_id, type, mission_id, task_id, routine_id, timestamp, metadata, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      id,
      event.userId,
      event.type,
      event.missionId || null,
      event.taskId || null,
      event.routineId || null,
      now,
      event.metadata ? JSON.stringify(event.metadata) : null,
      now
    );
  }

  public static getEvents(userId: string, limit: number = 100): any[] {
    const db = DatabaseService.getDb();
    return db.prepare('SELECT * FROM behavior_events WHERE user_id = ? ORDER BY timestamp DESC LIMIT ?').all(userId, limit);
  }
}
