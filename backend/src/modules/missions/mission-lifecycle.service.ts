// Authoritative Mission Lifecycle & Transaction State Machine
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { GamificationRepository } from '../../repositories/gamification.repository';

export type ValidMissionStatus =
  | 'SCHEDULED'
  | 'TRIGGERED'
  | 'ACTIVE'
  | 'SUBMITTED'
  | 'VERIFYING'
  | 'COMPLETED'
  | 'FAILED'
  | 'EXPIRED'
  | 'CANCELLED';

export class MissionLifecycleService {
  // Explicit State Transition Matrix
  private static validTransitions: Record<ValidMissionStatus, ValidMissionStatus[]> = {
    SCHEDULED: ['TRIGGERED', 'ACTIVE', 'CANCELLED', 'EXPIRED'],
    TRIGGERED: ['ACTIVE', 'EXPIRED', 'FAILED', 'CANCELLED'],
    ACTIVE: ['SUBMITTED', 'EXPIRED', 'FAILED'],
    SUBMITTED: ['VERIFYING', 'ACTIVE'],
    VERIFYING: ['COMPLETED', 'ACTIVE', 'FAILED'],
    COMPLETED: [], // Terminal State
    FAILED: ['SCHEDULED', 'ACTIVE'],
    EXPIRED: ['SCHEDULED'],
    CANCELLED: ['SCHEDULED']
  };

  public static canTransition(current: ValidMissionStatus, next: ValidMissionStatus): boolean {
    return this.validTransitions[current]?.includes(next) ?? false;
  }

  public static transitionMission(missionId: string, targetStatus: ValidMissionStatus): any {
    const db = DatabaseService.getDb();
    const mission = db.prepare('SELECT * FROM missions WHERE id = ?').get(missionId) as any;
    if (!mission) throw new Error(`Mission ${missionId} not found`);

    const currentStatus = mission.status as ValidMissionStatus;
    if (!this.canTransition(currentStatus, targetStatus)) {
      throw new Error(`Invalid state transition: Cannot transition mission from ${currentStatus} to ${targetStatus}`);
    }

    const now = new Date().toISOString();
    db.prepare('UPDATE missions SET status = ?, updated_at = ? WHERE id = ?').run(targetStatus, now, missionId);

    return db.prepare('SELECT * FROM missions WHERE id = ?').get(missionId);
  }

  /**
   * Atomic Transactional Mission Completion with Idempotency Guard
   */
  public static completeMissionAtomic(params: {
    missionId: string;
    userId: string;
    resistanceSeconds: number;
    baseXp: number;
    idempotencyKey?: string;
  }): { mission: any; xpAwarded: number; streak: any } {
    const db = DatabaseService.getDb();
    const mission = db.prepare('SELECT * FROM missions WHERE id = ?').get(params.missionId) as any;
    if (!mission) throw new Error(`Mission ${params.missionId} not found`);

    // 1. Idempotency Check
    if (mission.status === 'COMPLETED') {
      const streak = GamificationRepository.getStreak(params.userId);
      return {
        mission,
        xpAwarded: 0,
        streak
      };
    }

    // 2. State Transition Check
    if (mission.status !== 'VERIFYING' && mission.status !== 'ACTIVE' && mission.status !== 'SUBMITTED') {
      throw new Error(`Cannot complete mission with current status ${mission.status}`);
    }

    // 3. Compute Multiplier
    const isInstantAction = params.resistanceSeconds <= 120;
    const finalXp = isInstantAction ? Math.round(params.baseXp * 1.5) : params.baseXp;
    const now = new Date().toISOString();

    // 4. Atomic Execution: Update Mission + XP Ledger + Streak
    db.prepare(`
      UPDATE missions 
      SET status = 'COMPLETED', completed_at = ?, resistance_seconds = ?
      WHERE id = ?
    `).run(now, params.resistanceSeconds, params.missionId);

    db.prepare(`
      INSERT INTO xp_transactions (id, user_id, mission_id, amount, reason, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
    `).run(
      uuidv4(),
      params.userId,
      params.missionId,
      finalXp,
      isInstantAction ? 'MISSION_COMPLETED_INSTANT_ACTION' : 'MISSION_COMPLETED',
      now
    );

    // Update streak
    const streakRow = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(params.userId) as any;
    const currentStreak = streakRow ? streakRow.current_streak + 1 : 1;
    const longestStreak = streakRow ? Math.max(streakRow.longest_streak, currentStreak) : 1;
    const graceTokens = streakRow ? streakRow.grace_tokens : 1;

    db.prepare(`
      INSERT OR REPLACE INTO streaks (user_id, current_streak, longest_streak, grace_tokens, last_completed_date, updated_at)
      VALUES (?, ?, ?, ?, ?, ?)
    `).run(params.userId, currentStreak, longestStreak, graceTokens, now.substring(0, 10), now);

    const completedMission = db.prepare('SELECT * FROM missions WHERE id = ?').get(params.missionId);

    return {
      mission: completedMission,
      xpAwarded: finalXp,
      streak: { current_streak: currentStreak, longest_streak: longestStreak, grace_tokens: graceTokens }
    };
  }
}
