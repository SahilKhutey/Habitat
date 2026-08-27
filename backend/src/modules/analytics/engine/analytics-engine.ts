// Holistic Analytics & Insights Aggregator Engine
import { DatabaseService } from '../../../db/connection';
import { BehaviorEngine } from '../../behavior/engine/behavior-engine';
import { TimingEngine } from '../../behavior/engine/timing-engine';

export interface DisciplineOverview {
  userId: string;
  totalMissions: number;
  completedMissions: number;
  missedMissions: number;
  overallCompletionRate: number;
  averageDelayMinutes: number;
  strongestHabit: { name: string; consistencyRate: number; streak: number } | null;
  bestTimeWindow: string | null;
  needsAttention: string | null;
  disciplineScore: number;
}

export class AnalyticsEngine {
  /**
   * Generates a concise discipline overview for the user
   */
  public static getOverview(userId: string): DisciplineOverview {
    const db = DatabaseService.getDb();

    // 1. Mission Statistics
    const missionStats = db.prepare(`
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) as completed,
        SUM(CASE WHEN status = 'MISSED' OR status = 'CANCELLED' THEN 1 ELSE 0 END) as missed,
        AVG(CASE WHEN resistance_seconds IS NOT NULL THEN resistance_seconds ELSE 0 END) as avg_delay
      FROM missions
      WHERE user_id = ?
    `).get(userId) as any;

    const total = missionStats?.total || 0;
    const completed = missionStats?.completed || 0;
    const missed = missionStats?.missed || 0;
    const avgDelaySec = Math.round(missionStats?.avg_delay || 0);
    const overallCompletionRate = total > 0 ? Number(((completed / total) * 100).toFixed(1)) : 100.0;

    // 2. Strongest Habit
    const topTask = db.prepare(`
      SELECT 
        t.name,
        COUNT(m.id) as attempts,
        SUM(CASE WHEN m.status = 'COMPLETED' THEN 1 ELSE 0 END) as completions
      FROM missions m
      JOIN tasks t ON m.task_id = t.id
      WHERE m.user_id = ?
      GROUP BY t.id, t.name
      HAVING attempts >= 3
      ORDER BY (completions * 1.0 / attempts) DESC
      LIMIT 1
    `).get(userId) as any;

    let strongestHabit = null;
    if (topTask) {
      const cRate = Math.round((topTask.completions / topTask.attempts) * 100);
      strongestHabit = {
        name: topTask.name,
        consistencyRate: cRate,
        streak: topTask.completions
      };
    }

    // 3. Best Time Window
    const timing = TimingEngine.findOptimalWindow(userId);

    // 4. Discipline Score
    const gamification = db.prepare('SELECT discipline_score FROM user_gamification WHERE user_id = ?').get(userId) as any;
    const disciplineScore = gamification?.discipline_score || 85.0;

    // 5. Needs Attention Routine/Task
    const lowTask = db.prepare(`
      SELECT 
        t.name,
        COUNT(m.id) as attempts,
        SUM(CASE WHEN m.status = 'COMPLETED' THEN 1 ELSE 0 END) as completions
      FROM missions m
      JOIN tasks t ON m.task_id = t.id
      WHERE m.user_id = ?
      GROUP BY t.id, t.name
      HAVING attempts >= 3 AND (completions * 1.0 / attempts) < 0.6
      ORDER BY (completions * 1.0 / attempts) ASC
      LIMIT 1
    `).get(userId) as any;

    return {
      userId,
      totalMissions: total,
      completedMissions: completed,
      missedMissions: missed,
      overallCompletionRate,
      averageDelayMinutes: Math.round(avgDelaySec / 60),
      strongestHabit,
      bestTimeWindow: timing.bestWindow,
      needsAttention: lowTask ? lowTask.name : null,
      disciplineScore: Number(disciplineScore.toFixed(1))
    };
  }
}
