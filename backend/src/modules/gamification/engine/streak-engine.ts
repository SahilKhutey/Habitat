// Timezone-Aware Streak Progression & Grace Recovery Engine
import { DatabaseService } from '../../../db/connection';
import { StreakEntity } from '../domain/streak.entity';

export class StreakEngine {
  /**
   * Updates streak upon mission verification in accordance with user timezone date
   */
  public static updateStreak(userId: string, timezone: string = 'UTC'): {
    streak: StreakEntity;
    advanced: boolean;
    graceEarned: boolean;
  } {
    const db = DatabaseService.getDb();
    const now = new Date();

    // Format local date string according to timezone (e.g. "YYYY-MM-DD")
    const localDateStr = new Intl.DateTimeFormat('en-CA', {
      timeZone: timezone || 'UTC',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit'
    }).format(now);

    const row = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(userId) as any;
    let currentStreak = row?.current_streak ?? 0;
    let longestStreak = row?.longest_streak ?? 0;
    let graceTokens = row?.grace_tokens ?? 1;
    const lastDate = row?.last_completed_date;
    let advanced = false;
    let graceEarned = false;

    if (lastDate === localDateStr) {
      // Already qualified today
      return {
        streak: {
          userId,
          currentStreak,
          bestStreak: longestStreak,
          graceTokens,
          lastQualifiedDate: lastDate,
          recoveryUsed: Boolean(row?.recovery_used),
          updatedAt: new Date()
        },
        advanced: false,
        graceEarned: false
      };
    }

    // Check yesterday
    const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const yesterdayStr = new Intl.DateTimeFormat('en-CA', {
      timeZone: timezone || 'UTC',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit'
    }).format(yesterday);

    if (lastDate === yesterdayStr || !lastDate) {
      // Consecutive streak
      currentStreak += 1;
      advanced = true;
    } else {
      // Streak lapsed, reset to 1
      currentStreak = 1;
      advanced = true;
    }

    longestStreak = Math.max(longestStreak, currentStreak);

    // Earn 1 grace token every 14 streak days (Max 3 tokens)
    if (currentStreak % 14 === 0 && graceTokens < 3) {
      graceTokens += 1;
      graceEarned = true;
    }

    const timestamp = now.toISOString();
    db.prepare(`
      INSERT OR REPLACE INTO streaks (user_id, current_streak, longest_streak, grace_tokens, last_completed_date, recovery_used, updated_at)
      VALUES (?, ?, ?, ?, ?, 0, ?)
    `).run(userId, currentStreak, longestStreak, graceTokens, localDateStr, timestamp);

    return {
      streak: {
        userId,
        currentStreak,
        bestStreak: longestStreak,
        graceTokens,
        lastQualifiedDate: localDateStr,
        recoveryUsed: false,
        updatedAt: now
      },
      advanced,
      graceEarned
    };
  }

  /**
   * Consumes a Grace token to protect streak on missed day without fabricating completions
   */
  public static recoverStreak(userId: string): { success: boolean; streak: StreakEntity; message: string } {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(userId) as any;
    if (!row) throw new Error('STREAK_NOT_FOUND: No streak history found');

    if (row.grace_tokens <= 0) {
      throw new Error('NO_GRACE_TOKENS: No streak recovery tokens available in Grace Vault');
    }

    const newGraceTokens = row.grace_tokens - 1;
    const now = new Date().toISOString();

    db.prepare(`
      UPDATE streaks 
      SET grace_tokens = ?, recovery_used = 1, updated_at = ?
      WHERE user_id = ?
    `).run(newGraceTokens, now, userId);

    const updated = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(userId) as any;

    return {
      success: true,
      streak: {
        userId,
        currentStreak: updated.current_streak,
        bestStreak: updated.longest_streak,
        graceTokens: updated.grace_tokens,
        lastQualifiedDate: updated.last_completed_date,
        recoveryUsed: true,
        updatedAt: new Date()
      },
      message: 'Streak preserved using Grace Vault token. Keep going today!'
    };
  }
}
