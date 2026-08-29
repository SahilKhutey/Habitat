// Daily Planning Service & Approval Workflow
import { DatabaseService } from '../../../db/connection';
import { DailyPlannerEngine } from '../engine/daily-planner';
import { DailyPlanEntity } from '../domain/plan.entity';

export class PlanningService {
  /**
   * Retrieves today's active or proposed daily plan
   */
  public static getTodayPlan(userId: string): DailyPlanEntity {
    const db = DatabaseService.getDb();
    const today = new Date().toISOString().substring(0, 10);

    const row = db.prepare('SELECT * FROM daily_plans WHERE user_id = ? AND plan_date = ?').get(userId, today) as any;
    if (row) {
      return {
        id: row.id,
        userId: row.user_id,
        planDate: row.plan_date,
        scheduleItems: JSON.parse(row.schedule_items),
        conflicts: row.conflicts ? JSON.parse(row.conflicts) : [],
        status: row.status,
        createdAt: new Date(row.created_at),
        updatedAt: new Date(row.updated_at)
      };
    }

    return DailyPlannerEngine.generateDailyPlan(userId, today);
  }

  /**
   * Explicitly approves a proposed daily plan
   */
  public static approvePlan(planId: string, userId: string): DailyPlanEntity {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM daily_plans WHERE id = ? AND user_id = ?').get(planId, userId) as any;
    if (!row) {
      throw new Error('PLAN_NOT_FOUND: Daily plan not found');
    }

    const now = new Date().toISOString();
    db.prepare("UPDATE daily_plans SET status = 'APPROVED', updated_at = ? WHERE id = ?").run(now, planId);

    return {
      id: row.id,
      userId: row.user_id,
      planDate: row.plan_date,
      scheduleItems: JSON.parse(row.schedule_items),
      conflicts: row.conflicts ? JSON.parse(row.conflicts) : [],
      status: 'APPROVED',
      createdAt: new Date(row.created_at),
      updatedAt: new Date(now)
    };
  }
}
