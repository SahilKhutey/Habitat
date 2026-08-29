// Aggregate Wellness Analytics Service
import { DatabaseService } from '../../../db/connection';

export class WellnessAnalytics {
  public static getWeeklyWellnessSummary(userId: string) {
    const db = DatabaseService.getDb();
    const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

    const exercises = db.prepare('SELECT count(*) as count, COALESCE(SUM(duration_sec), 0) as duration FROM exercise_sessions WHERE user_id = ? AND started_at >= ?').get(userId, cutoff) as any;
    const hydration = db.prepare('SELECT count(DISTINCT date(timestamp)) as days, COALESCE(SUM(amount_ml), 0) as total FROM hydration_entries WHERE user_id = ? AND timestamp >= ?').get(userId, cutoff) as any;
    const sleep = db.prepare('SELECT COALESCE(AVG(duration_sec), 0) as avgSleep FROM sleep_sessions WHERE user_id = ? AND started_at >= ?').get(userId, cutoff) as any;

    return {
      userId,
      movementMinutes: Math.round(Number(exercises?.duration || 0) / 60),
      exerciseSessionsCount: Number(exercises?.count || 0),
      hydrationDaysMet: Number(hydration?.days || 0),
      averageSleepHours: Number((Number(sleep?.avgSleep || 0) / 3600).toFixed(1)),
      strongestArea: 'Exercise',
      growthOpportunity: 'Sleep consistency'
    };
  }
}
