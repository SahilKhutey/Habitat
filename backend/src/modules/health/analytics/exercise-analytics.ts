// Exercise Analytics Service
import { DatabaseService } from '../../../db/connection';

export class ExerciseAnalytics {
  public static getExerciseBreakdown(userId: string, days: number = 30) {
    const db = DatabaseService.getDb();
    const cutoff = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();

    const sessions = db.prepare(`
      SELECT category, count(*) as count, COALESCE(SUM(duration_sec), 0) as totalDurationSec
      FROM exercise_sessions
      WHERE user_id = ? AND started_at >= ?
      GROUP BY category
    `).all(userId, cutoff) as any[];

    return {
      userId,
      periodDays: days,
      categories: sessions.map((s) => ({
        category: s.category || 'OTHER',
        sessionsCount: s.count,
        totalMinutes: Math.round(s.totalDurationSec / 60)
      }))
    };
  }
}
