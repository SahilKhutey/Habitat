// Slow-Moving Discipline Score & Rolling Progress Engine
import { DatabaseService } from '../../../db/connection';
import { DisciplineScoreEntity } from '../domain/discipline-score.entity';

export class ScoreEngine {
  /**
   * Calculates slow-moving weighted Discipline Score (0 to 100) over rolling window
   * Formula: 0.40 * Completion + 0.25 * Consistency + 0.20 * Difficulty + 0.15 * Streak
   */
  public static calculateDisciplineScore(userId: string, windowDays: number = 30): DisciplineScoreEntity {
    const db = DatabaseService.getDb();
    const now = new Date();
    const windowStart = new Date(now.getTime() - windowDays * 24 * 60 * 60 * 1000).toISOString();

    // 1. Completion Rate
    const assignedRow = db.prepare(`
      SELECT COUNT(*) as count FROM missions 
      WHERE user_id = ? AND created_at >= ?
    `).get(userId, windowStart) as any;

    const completedRow = db.prepare(`
      SELECT COUNT(*) as count FROM missions 
      WHERE user_id = ? AND status = 'COMPLETED' AND created_at >= ?
    `).get(userId, windowStart) as any;

    const assigned = assignedRow?.count || 0;
    const completed = completedRow?.count || 0;
    const completionRate = assigned > 0 ? Math.min(1.0, completed / assigned) : 1.0;

    // 2. Consistency Rate (Days with at least 1 completed mission vs total days)
    const activeDaysRow = db.prepare(`
      SELECT COUNT(DISTINCT substr(created_at, 1, 10)) as count 
      FROM missions 
      WHERE user_id = ? AND status = 'COMPLETED' AND created_at >= ?
    `).get(userId, windowStart) as any;
    const activeDays = activeDaysRow?.count || 0;
    const consistencyRate = Math.min(1.0, activeDays / Math.max(1, windowDays));

    // 3. Difficulty Factor (Average difficulty of completed tasks)
    const diffRow = db.prepare(`
      SELECT AVG(t.difficulty) as avg_diff 
      FROM missions m 
      JOIN tasks t ON m.task_id = t.id 
      WHERE m.user_id = ? AND m.status = 'COMPLETED' AND m.created_at >= ?
    `).get(userId, windowStart) as any;
    const avgDiff = diffRow?.avg_diff || 1.5;
    const difficultyFactor = Math.min(1.0, avgDiff / 3.0); // Normalize 1-3 difficulty scale

    // 4. Streak Factor
    const streakRow = db.prepare('SELECT current_streak FROM streaks WHERE user_id = ?').get(userId) as any;
    const currentStreak = streakRow?.current_streak || 0;
    const streakFactor = Math.min(1.0, currentStreak / 30.0); // Target 30-day streak

    // 5. Weighted Score Calculation
    const weightedScore =
      0.40 * (completionRate * 100) +
      0.25 * (consistencyRate * 100) +
      0.20 * (difficultyFactor * 100) +
      0.15 * (streakFactor * 100);

    const score = Math.max(0, Math.min(100, Math.round(weightedScore)));

    // Sync to user_gamification
    db.prepare(`
      UPDATE user_gamification 
      SET discipline_score = ?, updated_at = ?
      WHERE user_id = ?
    `).run(score, now.toISOString(), userId);

    return {
      userId,
      score,
      completionRate: Number((completionRate * 100).toFixed(1)),
      consistencyRate: Number((consistencyRate * 100).toFixed(1)),
      difficultyFactor: Number((difficultyFactor * 100).toFixed(1)),
      streakFactor: Number((streakFactor * 100).toFixed(1)),
      rollingWindowDays: windowDays
    };
  }

  /**
   * Records or updates daily discipline statistics
   */
  public static recordDailyStat(userId: string, dateStr: string, xpEarned: number, isSuccess: boolean): void {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();

    const existing = db.prepare('SELECT * FROM daily_discipline_stats WHERE user_id = ? AND date = ?').get(userId, dateStr) as any;

    if (existing) {
      db.prepare(`
        UPDATE daily_discipline_stats 
        SET 
          tasks_assigned = tasks_assigned + 1,
          tasks_completed = tasks_completed + (CASE WHEN ? = 1 THEN 1 ELSE 0 END),
          tasks_failed = tasks_failed + (CASE WHEN ? = 0 THEN 1 ELSE 0 END),
          xp_earned = xp_earned + ?,
          updated_at = ?
        WHERE id = ?
      `).run(isSuccess ? 1 : 0, isSuccess ? 1 : 0, xpEarned, now, existing.id);
    } else {
      db.prepare(`
        INSERT INTO daily_discipline_stats (
          id, user_id, date, tasks_assigned, tasks_completed, tasks_failed, xp_earned, discipline_score, created_at, updated_at
        ) VALUES (?, ?, ?, 1, ?, ?, ?, 85.0, ?, ?)
      `).run(
        require('uuid').v4(),
        userId,
        dateStr,
        isSuccess ? 1 : 0,
        isSuccess ? 0 : 1,
        xpEarned,
        now,
        now
      );
    }
  }
}
