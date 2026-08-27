// Wellness Goals & Progress Service
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { WellnessGoalEntity, WellnessGoalType } from '../domain/hydration.entity';

export class WellnessService {
  /**
   * Creates a new personal wellness goal
   */
  public static createGoal(params: {
    userId: string;
    type: WellnessGoalType;
    target: number;
    unit: string;
    startDate?: Date;
    endDate?: Date;
  }): WellnessGoalEntity {
    if (params.target <= 0 || isNaN(params.target)) {
      throw new Error('INVALID_TARGET: Goal target must be a positive number');
    }

    const db = DatabaseService.getDb();
    const goalId = uuidv4();
    const now = new Date();
    const startDate = params.startDate || now;

    db.prepare(`
      INSERT INTO wellness_goals (
        id, user_id, type, target, unit, start_date, end_date, status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 'ACTIVE', ?, ?)
    `).run(
      goalId,
      params.userId,
      params.type,
      params.target,
      params.unit,
      startDate.toISOString(),
      params.endDate ? params.endDate.toISOString() : null,
      now.toISOString(),
      now.toISOString()
    );

    return {
      id: goalId,
      userId: params.userId,
      type: params.type,
      target: params.target,
      unit: params.unit,
      startDate,
      endDate: params.endDate,
      status: 'ACTIVE',
      createdAt: now,
      updatedAt: now
    };
  }

  /**
   * Retrieves active wellness goals for a user
   */
  public static getGoals(userId: string): WellnessGoalEntity[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare(`
      SELECT * FROM wellness_goals
      WHERE user_id = ? AND status = 'ACTIVE'
      ORDER BY created_at DESC
    `).all(userId) as any[];

    return rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      type: r.type,
      target: r.target,
      unit: r.unit,
      startDate: new Date(r.start_date),
      endDate: r.end_date ? new Date(r.end_date) : undefined,
      status: r.status,
      createdAt: new Date(r.created_at),
      updatedAt: new Date(r.updated_at)
    }));
  }

  /**
   * Updates goal status or target
   */
  public static updateGoal(params: {
    goalId: string;
    userId: string;
    target?: number;
    status?: 'ACTIVE' | 'PAUSED' | 'COMPLETED' | 'CANCELLED';
  }): WellnessGoalEntity {
    const db = DatabaseService.getDb();
    const existing = db.prepare('SELECT * FROM wellness_goals WHERE id = ? AND user_id = ?').get(params.goalId, params.userId) as any;
    if (!existing) throw new Error('GOAL_NOT_FOUND: Wellness goal not found');

    const updatedTarget = params.target !== undefined ? params.target : existing.target;
    const updatedStatus = params.status !== undefined ? params.status : existing.status;
    const now = new Date().toISOString();

    db.prepare('UPDATE wellness_goals SET target = ?, status = ?, updated_at = ? WHERE id = ?').run(
      updatedTarget,
      updatedStatus,
      now,
      params.goalId
    );

    return {
      id: params.goalId,
      userId: params.userId,
      type: existing.type,
      target: updatedTarget,
      unit: existing.unit,
      startDate: new Date(existing.start_date),
      endDate: existing.end_date ? new Date(existing.end_date) : undefined,
      status: updatedStatus,
      createdAt: new Date(existing.created_at),
      updatedAt: new Date(now)
    };
  }
}
