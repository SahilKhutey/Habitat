// Health Privacy & Granular Data Deletion Service
import { DatabaseService } from '../../../db/connection';

export class PrivacyService {
  /**
   * Deletes user's exercise records
   */
  public static deleteExerciseData(userId: string): { deleted: boolean; count: number } {
    const db = DatabaseService.getDb();
    const result = db.prepare('DELETE FROM exercise_sessions WHERE user_id = ?').run(userId);
    return { deleted: true, count: Number(result.changes) };
  }

  /**
   * Deletes user's hydration records
   */
  public static deleteHydrationData(userId: string): { deleted: boolean; count: number } {
    const db = DatabaseService.getDb();
    const result = db.prepare('DELETE FROM hydration_entries WHERE user_id = ?').run(userId);
    return { deleted: true, count: Number(result.changes) };
  }

  /**
   * Deletes user's sleep records
   */
  public static deleteSleepData(userId: string): { deleted: boolean; count: number } {
    const db = DatabaseService.getDb();
    const result = db.prepare('DELETE FROM sleep_sessions WHERE user_id = ?').run(userId);
    return { deleted: true, count: Number(result.changes) };
  }
}
