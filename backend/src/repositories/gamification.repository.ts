// Gamification & XP Ledger Repository Interface & Implementation
import { DatabaseService } from '../db/connection';
import { v4 as uuidv4 } from 'uuid';

export interface XpTransactionEntity {
  id: string;
  userId: string;
  missionId: string | null;
  amount: number;
  reason: string;
  createdAt: string;
}

export interface StreakEntity {
  userId: string;
  currentStreak: number;
  longestStreak: number;
  graceTokens: number;
  lastCompletedDate: string | null;
  updatedAt: string;
}

export class GamificationRepository {
  public static addXpTransaction(params: {
    userId: string;
    missionId?: string;
    amount: number;
    reason: string;
  }): XpTransactionEntity {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO xp_transactions (id, user_id, mission_id, amount, reason, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
    `).run(id, params.userId, params.missionId || null, params.amount, params.reason, now);

    return {
      id,
      userId: params.userId,
      missionId: params.missionId || null,
      amount: params.amount,
      reason: params.reason,
      createdAt: now
    };
  }

  public static getStreak(userId: string): StreakEntity {
    const db = DatabaseService.getDb();
    let row = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(userId) as any;

    if (!row) {
      const now = new Date().toISOString();
      db.prepare(`
        INSERT INTO streaks (user_id, current_streak, longest_streak, grace_tokens, updated_at)
        VALUES (?, 0, 0, 1, ?)
      `).run(userId, now);

      row = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(userId) as any;
    }

    return {
      userId: row.user_id,
      currentStreak: row.current_streak,
      longestStreak: row.longest_streak,
      graceTokens: row.grace_tokens,
      lastCompletedDate: row.last_completed_date,
      updatedAt: row.updated_at
    };
  }

  public static getTotalXp(userId: string): number {
    const db = DatabaseService.getDb();
    const result = db.prepare('SELECT COALESCE(SUM(amount), 0) as total FROM xp_transactions WHERE user_id = ?').get(userId) as any;
    return result ? result.total : 0;
  }
}
