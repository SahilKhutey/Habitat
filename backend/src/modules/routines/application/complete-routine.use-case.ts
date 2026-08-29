// Complete Routine Application Use Case
import { DatabaseService } from '../../../db/connection';

export class CompleteRoutineUseCase {
  public static execute(routineId: string, instanceDate: string, userId: string) {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT OR REPLACE INTO daily_plans (id, user_id, plan_date, schedule_items, conflicts, status, created_at, updated_at)
      VALUES (?, ?, ?, '[]', '[]', 'COMPLETED', ?, ?)
    `).run(`inst-${routineId}-${instanceDate}`, userId, instanceDate, now, now);

    return { routineId, instanceDate, status: 'COMPLETED' };
  }
}
