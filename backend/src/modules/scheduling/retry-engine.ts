// 5-Minute Inactivity Retry Engine
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';

export class RetryEngine {
  /**
   * Evaluates mission state and schedules the next retry attempt if still active.
   * If mission is COMPLETED or CANCELLED, returns null without scheduling.
   */
  public static processNextAttempt(missionId: string, retryIntervalMinutes: number = 5): {
    attemptNumber: number;
    scheduledAt: string;
    status: string;
  } | null {
    const db = DatabaseService.getDb();
    const mission = db.prepare('SELECT * FROM missions WHERE id = ?').get(missionId) as any;
    if (!mission) throw new Error('Mission not found');

    // 1. Completion & Cancellation Check
    if (mission.status === 'COMPLETED' || mission.status === 'CANCELLED') {
      this.cancelPendingRetries(missionId);
      return null;
    }

    // 2. Count existing attempts
    const attempts = db.prepare('SELECT COUNT(*) as count FROM mission_attempts WHERE mission_id = ?').get(missionId) as any;
    const nextAttemptNumber = (attempts?.count ?? 0) + 1;

    const now = new Date();
    const scheduledAt = new Date(now.getTime() + retryIntervalMinutes * 60 * 1000).toISOString();
    const attemptId = uuidv4();

    // 3. Persist Next Attempt Record
    db.prepare(`
      INSERT INTO mission_attempts (id, mission_id, attempt_index, triggered_at, status, siren_volume_level)
      VALUES (?, ?, ?, ?, 'SCHEDULED', ?)
    `).run(
      attemptId,
      missionId,
      nextAttemptNumber,
      scheduledAt,
      Math.min(100, 70 + (nextAttemptNumber - 1) * 15)
    );

    // 4. Update Mission Attempt Count & Status
    db.prepare(`
      UPDATE missions 
      SET attempt_count = ?, status = 'ACTIVE', updated_at = ?
      WHERE id = ?
    `).run(nextAttemptNumber, now.toISOString(), missionId);

    return {
      attemptNumber: nextAttemptNumber,
      scheduledAt,
      status: 'SCHEDULED'
    };
  }

  /**
   * Atomically cancels all pending future retry attempts for a mission
   */
  public static cancelPendingRetries(missionId: string): void {
    const db = DatabaseService.getDb();
    db.prepare("UPDATE mission_attempts SET status = 'CANCELLED' WHERE mission_id = ? AND status = 'SCHEDULED'").run(missionId);
  }
}
