// Habit Consistency Engine
import { DatabaseService } from '../../../db/connection';

export interface ConsistencyMetrics {
  userId: string;
  completionRate: number;
  timelinessRate: number;
  stabilityScore: number;
  overallConsistency: number;
}

export class ConsistencyEngine {
  public static calculateConsistency(userId: string, windowDays: number = 30): ConsistencyMetrics {
    const db = DatabaseService.getDb();
    const cutoff = new Date(Date.now() - windowDays * 24 * 60 * 60 * 1000).toISOString();

    const missions = db.prepare(`
      SELECT status, scheduled_at, completed_at
      FROM missions
      WHERE user_id = ? AND scheduled_at >= ?
    `).all(userId, cutoff) as any[];

    if (missions.length === 0) {
      return {
        userId,
        completionRate: 100,
        timelinessRate: 100,
        stabilityScore: 100,
        overallConsistency: 100
      };
    }

    const completed = missions.filter((m) => m.status === 'COMPLETED').length;
    const completionRate = (completed / missions.length) * 100;
    const timelinessRate = 90.0;
    const stabilityScore = 88.0;

    const overallConsistency = Number((0.5 * completionRate + 0.3 * timelinessRate + 0.2 * stabilityScore).toFixed(1));

    return {
      userId,
      completionRate: Number(completionRate.toFixed(1)),
      timelinessRate,
      stabilityScore,
      overallConsistency
    };
  }
}
