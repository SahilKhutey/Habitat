// User Repository
import { DatabaseService } from '../connection';
import { User } from '../../domain/types';

export class UserRepository {
  public static getById(id: string): User | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM users WHERE id = ?').get(id) as any;
    if (!row) return null;
    return this.mapToUser(row);
  }

  public static getFirstUser(): User | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM users ORDER BY created_at ASC LIMIT 1').get() as any;
    if (!row) return null;
    return this.mapToUser(row);
  }

  public static updateStats(
    userId: string,
    updates: {
      disciplineScore?: number;
      currentStreak?: number;
      longestStreak?: number;
      totalXp?: number;
      graceTokens?: number;
      autonomyLevel?: 1 | 2 | 3 | 4 | 5;
    }
  ): void {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    const user = this.getById(userId);
    if (!user) return;

    const stmt = db.prepare(`
      UPDATE users 
      SET discipline_score = ?, current_streak = ?, longest_streak = ?, total_xp = ?, grace_tokens = ?, autonomy_level = ?, updated_at = ?
      WHERE id = ?
    `);

    stmt.run(
      updates.disciplineScore ?? user.disciplineScore,
      updates.currentStreak ?? user.currentStreak,
      updates.longestStreak ?? user.longestStreak,
      updates.totalXp ?? user.totalXp,
      updates.graceTokens ?? user.graceTokens,
      updates.autonomyLevel ?? user.autonomyLevel,
      now,
      userId
    );
  }

  private static mapToUser(row: any): User {
    return {
      id: row.id,
      email: row.email,
      displayName: row.display_name,
      timezone: row.timezone,
      disciplineScore: row.discipline_score,
      autonomyLevel: row.autonomy_level,
      currentStreak: row.current_streak,
      longestStreak: row.longest_streak,
      totalXp: row.total_xp,
      graceTokens: row.grace_tokens,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };
  }
}
