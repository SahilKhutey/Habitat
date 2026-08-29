// Discipline Profile Service with Versioning
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { DisciplineProfileEntity, CoachingStyle, PlanningAutonomy } from '../domain/discipline-profile.entity';

export class DisciplineProfileService {
  /**
   * Retrieves or initializes a user's personal discipline profile
   */
  public static getProfile(userId: string): DisciplineProfileEntity {
    const db = DatabaseService.getDb();
    let row = db.prepare('SELECT * FROM discipline_profiles WHERE user_id = ?').get(userId) as any;

    if (!row) {
      const id = uuidv4();
      const now = new Date().toISOString();
      db.prepare(`
        INSERT INTO discipline_profiles (
          id, user_id, preferred_wake, preferred_sleep, consistency, completion_rate,
          preferred_days, preferred_times, strengths, friction_points, coaching_style,
          planning_autonomy, version, created_at, updated_at
        ) VALUES (
          ?, ?, '06:30', '22:30', 84.0, 88.0,
          '["MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY"]',
          '{"peakFocusWindow":"07:00-09:00","exerciseWindow":"07:00"}',
          '["Morning execution velocity","Physical proof compliance"]',
          '["Late evening fatigue","Multi-task scheduling overlaps"]',
          'DIRECT', 'ASSISTED', 1, ?, ?
        )
      `).run(id, userId, now, now);

      row = db.prepare('SELECT * FROM discipline_profiles WHERE id = ?').get(id) as any;
    }

    return {
      id: row.id,
      userId: row.user_id,
      preferredWake: row.preferred_wake || '06:30',
      preferredSleep: row.preferred_sleep || '22:30',
      consistency: Number(row.consistency) || 84.0,
      completionRate: Number(row.completion_rate) || 88.0,
      preferredDays: row.preferred_days ? JSON.parse(row.preferred_days) : [],
      preferredTimes: row.preferred_times ? JSON.parse(row.preferred_times) : { peakFocusWindow: '07:00-09:00', exerciseWindow: '07:00' },
      strengths: row.strengths ? JSON.parse(row.strengths) : [],
      frictionPoints: row.friction_points ? JSON.parse(row.friction_points) : [],
      coachingStyle: (row.coaching_style as CoachingStyle) || 'DIRECT',
      planningAutonomy: (row.planning_autonomy as PlanningAutonomy) || 'ASSISTED',
      version: row.version || 1,
      createdAt: new Date(row.created_at),
      updatedAt: new Date(row.updated_at)
    };
  }

  /**
   * Updates user discipline preferences and increments profile version
   */
  public static updateProfile(userId: string, updates: Partial<{
    preferredWake: string;
    preferredSleep: string;
    coachingStyle: CoachingStyle;
    planningAutonomy: PlanningAutonomy;
  }>): DisciplineProfileEntity {
    const db = DatabaseService.getDb();
    const current = this.getProfile(userId);
    const newVersion = current.version + 1;
    const now = new Date().toISOString();

    const wake = updates.preferredWake || current.preferredWake;
    const sleep = updates.preferredSleep || current.preferredSleep;
    const style = updates.coachingStyle || current.coachingStyle;
    const autonomy = updates.planningAutonomy || current.planningAutonomy;

    db.prepare(`
      UPDATE discipline_profiles
      SET preferred_wake = ?, preferred_sleep = ?, coaching_style = ?, planning_autonomy = ?, version = ?, updated_at = ?
      WHERE user_id = ?
    `).run(wake, sleep, style, autonomy, newVersion, now, userId);

    return this.getProfile(userId);
  }
}
