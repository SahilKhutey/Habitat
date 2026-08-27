// Discipline and Wellness Correlation Engine
import { DatabaseService } from '../../../db/connection';

export interface CorrelationInsight {
  hasSufficientData: boolean;
  totalDaysEvaluated: number;
  routineCompletionRateWithMorningRoutine: number;
  routineCompletionRateWithoutMorningRoutine: number;
  insightMessage: string;
}

export class WellnessCorrelationEngine {
  /**
   * Analyzes association between discipline routine completion and wellness goal attainment
   * Enforces minimum observation threshold (>= 14 days)
   */
  public static analyzeDisciplineWellnessCorrelation(userId: string): CorrelationInsight {
    const db = DatabaseService.getDb();
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

    // Query daily stats and exercise sessions
    const missionDays = db.prepare(`
      SELECT 
        substr(scheduled_at, 1, 10) as date_str,
        SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) as completed_count,
        COUNT(*) as total_count
      FROM missions
      WHERE user_id = ? AND scheduled_at >= ?
      GROUP BY date_str
    `).all(userId, thirtyDaysAgo) as any[];

    const exerciseDays = db.prepare(`
      SELECT DISTINCT substr(started_at, 1, 10) as date_str
      FROM exercise_sessions
      WHERE user_id = ? AND started_at >= ?
    `).all(userId, thirtyDaysAgo) as any[];

    const exerciseDateSet = new Set(exerciseDays.map((e) => e.date_str));
    const totalDays = missionDays.length;

    if (totalDays < 14) {
      return {
        hasSufficientData: false,
        totalDaysEvaluated: totalDays,
        routineCompletionRateWithMorningRoutine: 0,
        routineCompletionRateWithoutMorningRoutine: 0,
        insightMessage: 'Not enough correlation data yet (minimum 14 days needed for behavioral association).'
      };
    }

    let completedRoutineDays = 0;
    let completedRoutineAndExercised = 0;

    let missedRoutineDays = 0;
    let missedRoutineAndExercised = 0;

    for (const d of missionDays) {
      const isRoutineCompleted = d.completed_count > 0 && d.completed_count === d.total_count;
      const didExercise = exerciseDateSet.has(d.date_str);

      if (isRoutineCompleted) {
        completedRoutineDays++;
        if (didExercise) completedRoutineAndExercised++;
      } else {
        missedRoutineDays++;
        if (didExercise) missedRoutineAndExercised++;
      }
    }

    const rateWithMorning = completedRoutineDays > 0 ? Math.round((completedRoutineAndExercised / completedRoutineDays) * 100) : 0;
    const rateWithoutMorning = missedRoutineDays > 0 ? Math.round((missedRoutineAndExercised / missedRoutineDays) * 100) : 0;

    let insightMessage = 'Your exercise habits and routine execution show steady balance.';
    if (rateWithMorning > rateWithoutMorning + 15) {
      insightMessage = `Exercise completion is observed to be higher (${rateWithMorning}%) on days when your morning discipline routine is completed vs days without (${rateWithoutMorning}%).`;
    }

    return {
      hasSufficientData: true,
      totalDaysEvaluated: totalDays,
      routineCompletionRateWithMorningRoutine: rateWithMorning,
      routineCompletionRateWithoutMorningRoutine: rateWithoutMorning,
      insightMessage
    };
  }
}
