// Authoritative Gamification SQLite Repository
import { DatabaseService } from '../../../db/connection';
import { XPTransactionEntity } from '../domain/xp.entity';
import { StreakEntity } from '../domain/streak.entity';

export class GamificationRepository {
  public static getStreak(userId: string): StreakEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(userId) as any;
    if (!row) return null;
    return {
      userId: row.user_id,
      currentStreak: row.current_streak,
      bestStreak: row.longest_streak,
      graceTokens: row.grace_tokens,
      lastQualifiedDate: row.last_completed_date,
      recoveryUsed: Boolean(row.recovery_used),
      updatedAt: new Date(row.updated_at)
    };
  }

  public static upsertStreak(userId: string, currentStreak: number, bestStreak: number, graceTokens: number, lastQualifiedDate: string): void {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    db.prepare(`
      INSERT INTO streaks (user_id, current_streak, longest_streak, grace_tokens, last_completed_date, updated_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(user_id) DO UPDATE SET
        current_streak = excluded.current_streak,
        longest_streak = excluded.longest_streak,
        grace_tokens = excluded.grace_tokens,
        last_completed_date = excluded.last_completed_date,
        updated_at = excluded.updated_at
    `).run(userId, currentStreak, bestStreak, graceTokens, lastQualifiedDate, now);
  }

  public static insertXpTransaction(tx: XPTransactionEntity): void {
    const db = DatabaseService.getDb();
    db.prepare(`
      INSERT INTO xp_transactions (id, user_id, amount, source_type, source_id, reason, idempotency_key, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).run(tx.id, tx.userId, tx.amount, tx.sourceType, tx.sourceId || null, tx.reason, tx.idempotencyKey || null, tx.createdAt.toISOString());
  }

  public static findXpByIdempotencyKey(key: string): any {
    const db = DatabaseService.getDb();
    return db.prepare('SELECT id FROM xp_transactions WHERE idempotency_key = ?').get(key);
  }

  public static sumTotalXp(userId: string): number {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT COALESCE(SUM(amount), 0) as total FROM xp_transactions WHERE user_id = ?').get(userId) as any;
    return Number(row?.total) || 0;
  }
}
