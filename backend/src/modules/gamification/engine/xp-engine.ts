// Immutable XP Ledger Engine & Anti-Gaming Controller
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { XPSourceType } from '../domain/xp.entity';

export class XpEngine {
  /**
   * Appends an immutable XP transaction with strict idempotency protection
   */
  public static awardXp(params: {
    userId: string;
    amount: number;
    sourceType: XPSourceType;
    sourceId?: string;
    reason: string;
    idempotencyKey?: string;
  }): { success: boolean; isDuplicate: boolean; amount: number; totalXp: number } {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();

    // 1. Idempotency Check: Prevent duplicate awards
    if (params.idempotencyKey) {
      const existing = db.prepare('SELECT id FROM xp_transactions WHERE idempotency_key = ?').get(params.idempotencyKey) as any;
      if (existing) {
        const sumRow = db.prepare('SELECT SUM(amount) as total FROM xp_transactions WHERE user_id = ?').get(params.userId) as any;
        return {
          success: true,
          isDuplicate: true,
          amount: 0,
          totalXp: sumRow?.total ?? 0
        };
      }
    }

    // 2. Anti-Gaming Check: Limit daily repetitive reward exploits
    const todayStr = now.substring(0, 10);
    const dailyCountRow = db.prepare(`
      SELECT COUNT(*) as count 
      FROM xp_transactions 
      WHERE user_id = ? AND source_type = ? AND source_id = ? AND created_at LIKE ?
    `).get(params.userId, params.sourceType, params.sourceId || '', `${todayStr}%`) as any;

    let effectiveAmount = params.amount;
    if (dailyCountRow && dailyCountRow.count >= 3) {
      effectiveAmount = 0; // Cap repetitive task rewards to 3x per day
    } else if (dailyCountRow && dailyCountRow.count === 2) {
      effectiveAmount = Math.round(params.amount * 0.5); // Reduced 50% on 3rd attempt
    }

    // 3. Append to Immutable Ledger
    const transactionId = uuidv4();
    db.prepare(`
      INSERT INTO xp_transactions (id, user_id, mission_id, amount, reason, source_type, source_id, idempotency_key, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      transactionId,
      params.userId,
      params.sourceId || null,
      effectiveAmount,
      params.reason,
      params.sourceType,
      params.sourceId || null,
      params.idempotencyKey || null,
      now
    );

    // 4. Update Cached Total in UserGamification
    const sumRow = db.prepare('SELECT SUM(amount) as total FROM xp_transactions WHERE user_id = ?').get(params.userId) as any;
    const totalXp = sumRow?.total ?? 0;

    db.prepare(`
      INSERT OR REPLACE INTO user_gamification (user_id, total_xp, level, discipline_score, created_at, updated_at)
      VALUES (
        ?, 
        ?, 
        COALESCE((SELECT level FROM user_gamification WHERE user_id = ?), 1),
        COALESCE((SELECT discipline_score FROM user_gamification WHERE user_id = ?), 0.0),
        COALESCE((SELECT created_at FROM user_gamification WHERE user_id = ?), ?),
        ?
      )
    `).run(params.userId, totalXp, params.userId, params.userId, params.userId, now, now);

    return {
      success: true,
      isDuplicate: false,
      amount: effectiveAmount,
      totalXp
    };
  }

  /**
   * Sums all valid ledger entries
   */
  public static getTotalXp(userId: string): number {
    const db = DatabaseService.getDb();
    const sumRow = db.prepare('SELECT SUM(amount) as total FROM xp_transactions WHERE user_id = ?').get(userId) as any;
    return sumRow?.total ?? 0;
  }
}
