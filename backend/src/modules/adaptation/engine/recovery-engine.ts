// Recovery Protocol & Sustainable Routine Formulator
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';

export interface RecoveryPlan {
  planId: string;
  userId: string;
  durationDays: number;
  startDate: string;
  endDate: string;
  coreEssentialTaskIds: string[];
  optionalTaskIds: string[];
  reason: string;
  streakPreserved: boolean;
}

export class RecoveryEngine {
  /**
   * Evaluates if user qualifies for a Recovery Protocol (e.g. 7-day completion < 40%)
   */
  public static evaluateRecoveryEligibility(userId: string): { isEligible: boolean; recentCompletionRate: number; reason: string } {
    const db = DatabaseService.getDb();
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

    const row = db.prepare(`
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) as completed
      FROM missions
      WHERE user_id = ? AND scheduled_at >= ?
    `).get(userId, sevenDaysAgo) as any;

    const total = row?.total || 0;
    const completed = row?.completed || 0;
    const rate = total > 0 ? Math.round((completed / total) * 100) : 100;

    if (total >= 5 && rate < 45) {
      return {
        isEligible: true,
        recentCompletionRate: rate,
        reason: `Recent 7-day completion has dropped to ${rate}%. A 3-day recovery protocol can rebuild positive momentum.`
      };
    }

    return {
      isEligible: false,
      recentCompletionRate: rate,
      reason: 'Discipline momentum is stable.'
    };
  }

  /**
   * Generates a temporary 3-day Recovery Plan
   */
  public static createRecoveryPlan(params: {
    userId: string;
    durationDays?: number;
    reason?: string;
  }): RecoveryPlan {
    const days = params.durationDays || 3;
    const now = new Date();
    const end = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);

    const db = DatabaseService.getDb();
    const tasks = db.prepare('SELECT id, difficulty, category FROM tasks WHERE user_id = ? OR is_starter = 1').all(params.userId) as any[];

    // Essential tasks: difficulty 1 or 2, category HEALTH/MIND
    const coreEssentialTaskIds: string[] = [];
    const optionalTaskIds: string[] = [];

    for (const t of tasks) {
      if ((t.difficulty || 1) <= 2 && (t.category === 'HEALTH' || t.category === 'MIND' || t.category === 'GENERAL')) {
        if (coreEssentialTaskIds.length < 2) {
          coreEssentialTaskIds.push(t.id);
          continue;
        }
      }
      optionalTaskIds.push(t.id);
    }

    if (coreEssentialTaskIds.length === 0) {
      coreEssentialTaskIds.push('tpl-hydrate-glass', 'tpl-brush-teeth');
    }

    return {
      planId: uuidv4(),
      userId: params.userId,
      durationDays: days,
      startDate: now.toISOString().substring(0, 10),
      endDate: end.toISOString().substring(0, 10),
      coreEssentialTaskIds,
      optionalTaskIds,
      reason: params.reason || 'Momentum recovery protocol (essential anchors active, heavy tasks optional)',
      streakPreserved: true
    };
  }
}
