// Timing Optimization Engine & Success Window Evaluator
import { DatabaseService } from '../../../db/connection';
import { TimePerformance } from '../domain/task-performance.entity';

export interface OptimalTimingResult {
  hasSufficientData: boolean;
  totalObservations: number;
  bestHour: number | null;
  bestWindow: string | null;
  bestSuccessRate: number;
  currentWindowRate?: number;
  recommendation?: string;
  hourlyStats: TimePerformance[];
}

export class TimingEngine {
  /**
   * Calculates success rate by hour of the day (0 - 23)
   */
  public static calculateSuccessByHour(userId: string, taskId?: string): TimePerformance[] {
    const db = DatabaseService.getDb();
    const query = taskId
      ? db.prepare(`
          SELECT 
            strftime('%H', scheduled_at) as hour_str,
            COUNT(*) as attempts,
            SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) as completions
          FROM missions
          WHERE user_id = ? AND task_id = ?
          GROUP BY hour_str
          ORDER BY hour_str ASC
        `).all(userId, taskId) as any[]
      : db.prepare(`
          SELECT 
            strftime('%H', scheduled_at) as hour_str,
            COUNT(*) as attempts,
            SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) as completions
          FROM missions
          WHERE user_id = ?
          GROUP BY hour_str
          ORDER BY hour_str ASC
        `).all(userId) as any[];

    const statsMap = new Map<number, { attempts: number; completions: number }>();
    for (const r of query) {
      const hour = parseInt(r.hour_str, 10);
      if (!isNaN(hour)) {
        statsMap.set(hour, {
          attempts: Number(r.attempts),
          completions: Number(r.completions)
        });
      }
    }

    const results: TimePerformance[] = [];
    for (let h = 0; h < 24; h++) {
      const data = statsMap.get(h) || { attempts: 0, completions: 0 };
      const successRate = data.attempts > 0 ? Number(((data.completions / data.attempts) * 100).toFixed(1)) : 0.0;
      results.push({
        hour: h,
        attempts: data.attempts,
        completions: data.completions,
        successRate
      });
    }

    return results;
  }

  /**
   * Finds the optimal time window with strict minimum sample threshold (>= 5)
   */
  public static findOptimalWindow(userId: string, taskId?: string): OptimalTimingResult {
    const hourly = this.calculateSuccessByHour(userId, taskId);
    const totalObservations = hourly.reduce((sum, h) => sum + h.attempts, 0);

    if (totalObservations < 5) {
      return {
        hasSufficientData: false,
        totalObservations,
        bestHour: null,
        bestWindow: null,
        bestSuccessRate: 0,
        recommendation: 'Not enough behavioral data yet (minimum 5 observations needed).',
        hourlyStats: hourly
      };
    }

    // Filter hours with at least 2 attempts
    const validHours = hourly.filter((h) => h.attempts >= 2);
    if (validHours.length === 0) {
      return {
        hasSufficientData: false,
        totalObservations,
        bestHour: null,
        bestWindow: null,
        bestSuccessRate: 0,
        recommendation: 'Not enough repeated time patterns yet.',
        hourlyStats: hourly
      };
    }

    // Sort by highest success rate, then highest attempts
    validHours.sort((a, b) => b.successRate - a.successRate || b.attempts - a.attempts);
    const best = validHours[0];
    const nextHour = (best.hour + 1) % 24;
    const bestWindow = `${String(best.hour).padStart(2, '0')}:00–${String(nextHour).padStart(2, '0')}:00`;

    return {
      hasSufficientData: true,
      totalObservations,
      bestHour: best.hour,
      bestWindow,
      bestSuccessRate: best.successRate,
      recommendation: `You achieve your highest consistency (${best.successRate}%) during ${bestWindow}.`,
      hourlyStats: hourly
    };
  }
}
