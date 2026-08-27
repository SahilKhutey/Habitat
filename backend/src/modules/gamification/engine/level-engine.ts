// Level Progression Engine & Level-Up Event Dispatcher
import { DatabaseService } from '../../../db/connection';
import { LevelProgressEntity } from '../domain/level.entity';

export class LevelEngine {
  /**
   * Calculates level progression using quadratic curve: Threshold(L) = 50 * L * (L - 1)
   */
  public static calculateLevel(totalXp: number): LevelProgressEntity {
    let level = 1;
    while (true) {
      const nextThreshold = 50 * level * (level + 1);
      if (totalXp < nextThreshold) {
        break;
      }
      level++;
    }

    const currentLevelBaseXp = 50 * (level - 1) * level;
    const nextLevelBaseXp = 50 * level * (level + 1);
    const xpIntoCurrentLevel = Math.max(0, totalXp - currentLevelBaseXp);
    const xpNeededForNextLevel = Math.max(1, nextLevelBaseXp - currentLevelBaseXp);
    const progressPercent = Math.min(100, Math.round((xpIntoCurrentLevel / xpNeededForNextLevel) * 100));

    return {
      level,
      totalXp,
      currentLevelBaseXp,
      nextLevelBaseXp,
      xpIntoCurrentLevel,
      xpNeededForNextLevel,
      progressPercent
    };
  }

  /**
   * Updates cached user level and detects level-up transition
   */
  public static syncUserLevel(userId: string, totalXp: number): {
    levelProgress: LevelProgressEntity;
    isLevelUp: boolean;
    previousLevel: number;
    newLevel: number;
  } {
    const db = DatabaseService.getDb();
    const userRow = db.prepare('SELECT level FROM user_gamification WHERE user_id = ?').get(userId) as any;
    const previousLevel = userRow?.level ?? 1;

    const levelProgress = this.calculateLevel(totalXp);
    const isLevelUp = levelProgress.level > previousLevel;
    const now = new Date().toISOString();

    db.prepare(`
      INSERT OR REPLACE INTO user_gamification (user_id, total_xp, level, discipline_score, created_at, updated_at)
      VALUES (
        ?, 
        ?, 
        ?, 
        COALESCE((SELECT discipline_score FROM user_gamification WHERE user_id = ?), 0.0),
        COALESCE((SELECT created_at FROM user_gamification WHERE user_id = ?), ?),
        ?
      )
    `).run(userId, totalXp, levelProgress.level, userId, userId, now, now);

    return {
      levelProgress,
      isLevelUp,
      previousLevel,
      newLevel: levelProgress.level
    };
  }
}
