// Routines Infrastructure SQLite Repository
import { DatabaseService } from '../../../db/connection';
import { RoutineEntity } from '../domain/routine.entity';

export class RoutinesRepository {
  public static findById(id: string): any {
    const db = DatabaseService.getDb();
    return db.prepare('SELECT * FROM routines WHERE id = ?').get(id);
  }

  public static findByUserId(userId: string): any[] {
    const db = DatabaseService.getDb();
    return db.prepare('SELECT * FROM routines WHERE user_id = ? AND is_active = 1 ORDER BY created_at DESC').all(userId) as any[];
  }

  public static insert(routine: {
    id: string;
    userId: string;
    name: string;
    description?: string;
    category: string;
    scheduleRule: any;
    tasks: any[];
    version?: number;
  }): void {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO routines (id, user_id, name, description, category, schedule_rule, tasks, version, is_active, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
    `).run(
      routine.id,
      routine.userId,
      routine.name,
      routine.description || null,
      routine.category,
      JSON.stringify(routine.scheduleRule),
      JSON.stringify(routine.tasks),
      routine.version || 1,
      now,
      now
    );
  }

  public static update(id: string, updates: any): void {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();

    db.prepare(`
      UPDATE routines
      SET name = COALESCE(?, name),
          description = COALESCE(?, description),
          schedule_rule = COALESCE(?, schedule_rule),
          tasks = COALESCE(?, tasks),
          version = COALESCE(?, version),
          is_active = COALESCE(?, is_active),
          updated_at = ?
      WHERE id = ?
    `).run(
      updates.name || null,
      updates.description || null,
      updates.scheduleRule ? JSON.stringify(updates.scheduleRule) : null,
      updates.tasks ? JSON.stringify(updates.tasks) : null,
      updates.version || null,
      updates.isActive !== undefined ? (updates.isActive ? 1 : 0) : null,
      now,
      id
    );
  }
}
