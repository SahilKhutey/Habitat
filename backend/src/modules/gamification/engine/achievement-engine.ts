// Declarative Achievement Evaluation & Unlock Engine
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { AchievementEntity } from '../domain/achievement.entity';
import { XpEngine } from './xp-engine';

export const CANONICAL_ACHIEVEMENTS: Omit<AchievementEntity, 'id'>[] = [
  {
    code: 'FIRST_STEP',
    name: 'First Victory',
    description: 'Completed your very first discipline mission',
    requirement: { type: 'MISSION_COUNT', value: 1 },
    xpReward: 50,
    active: true
  },
  {
    code: 'FIRST_7_DAY_STREAK',
    name: 'Iron Momentum',
    description: 'Maintained a 7-day unbroken discipline streak',
    requirement: { type: 'STREAK', value: 7 },
    xpReward: 150,
    active: true
  },
  {
    code: 'FIRST_30_DAY_STREAK',
    name: 'Consistency Master',
    description: 'Achieved 30 consecutive days of discipline execution',
    requirement: { type: 'STREAK', value: 30 },
    xpReward: 500,
    active: true
  },
  {
    code: 'TASK_100',
    name: 'Centurion of Habit',
    description: 'Completed 100 discipline missions successfully',
    requirement: { type: 'MISSION_COUNT', value: 100 },
    xpReward: 300,
    active: true
  },
  {
    code: 'EARLY_RISER',
    name: 'Dawn Sovereign',
    description: 'Executed 5 morning missions before 07:00 AM',
    requirement: { type: 'EARLY_RISER', value: 5 },
    xpReward: 100,
    active: true
  }
];

export class AchievementEngine {
  /**
   * Seeds canonical achievements into DB if not present
   */
  public static seedAchievements(): void {
    const db = DatabaseService.getDb();
    for (const ach of CANONICAL_ACHIEVEMENTS) {
      db.prepare(`
        INSERT OR IGNORE INTO achievements (id, code, name, description, requirement, xp_reward, active)
        VALUES (?, ?, ?, ?, ?, ?, 1)
      `).run(uuidv4(), ach.code, ach.name, ach.description, JSON.stringify(ach.requirement), ach.xpReward);
    }
  }

  /**
   * Evaluates user stats and unlocks qualifying achievements idempotently
   */
  public static evaluateAchievements(userId: string): AchievementEntity[] {
    const db = DatabaseService.getDb();
    this.seedAchievements();

    // 1. Gather User Metrics
    const completedCountRow = db.prepare("SELECT COUNT(*) as count FROM missions WHERE user_id = ? AND status = 'COMPLETED'").get(userId) as any;
    const completedCount = completedCountRow?.count || 0;

    const streakRow = db.prepare('SELECT current_streak FROM streaks WHERE user_id = ?').get(userId) as any;
    const currentStreak = streakRow?.current_streak || 0;

    const earlyCountRow = db.prepare("SELECT COUNT(*) as count FROM xp_transactions WHERE user_id = ? AND reason LIKE '%SPEED%'").get(userId) as any;
    const earlyCount = earlyCountRow?.count || 0;

    // 2. Query All Active Achievements
    const allAchievements = db.prepare('SELECT * FROM achievements WHERE active = 1').all() as any[];
    const unlockedRows = db.prepare('SELECT achievement_id FROM user_achievements WHERE user_id = ?').all(userId) as any[];
    const unlockedIds = new Set(unlockedRows.map((r) => r.achievement_id));

    const newlyUnlocked: AchievementEntity[] = [];
    const now = new Date().toISOString();

    for (const ach of allAchievements) {
      if (unlockedIds.has(ach.id)) continue;

      const req = JSON.parse(ach.requirement);
      let qualifies = false;

      if (req.type === 'MISSION_COUNT' && completedCount >= req.value) qualifies = true;
      if (req.type === 'STREAK' && currentStreak >= req.value) qualifies = true;
      if (req.type === 'EARLY_RISER' && earlyCount >= req.value) qualifies = true;

      if (qualifies) {
        db.prepare(`
          INSERT OR IGNORE INTO user_achievements (id, user_id, achievement_id, unlocked_at)
          VALUES (?, ?, ?, ?)
        `).run(uuidv4(), userId, ach.id, now);

        if (ach.xp_reward > 0) {
          XpEngine.awardXp({
            userId,
            amount: ach.xp_reward,
            sourceType: 'ACHIEVEMENT',
            sourceId: ach.id,
            reason: `Achievement Unlocked: ${ach.name}`,
            idempotencyKey: `ACHIEVEMENT:${userId}:${ach.id}`
          });
        }

        newlyUnlocked.push({
          id: ach.id,
          code: ach.code,
          name: ach.name,
          description: ach.description,
          requirement: req,
          xpReward: ach.xp_reward,
          active: true,
          unlockedAt: now,
          isUnlocked: true
        });
      }
    }

    return newlyUnlocked;
  }

  /**
   * Retrieves all achievements with user unlock status
   */
  public static getUserAchievements(userId: string): AchievementEntity[] {
    const db = DatabaseService.getDb();
    this.seedAchievements();

    const rows = db.prepare(`
      SELECT 
        a.id, a.code, a.name, a.description, a.requirement, a.xp_reward, a.active,
        ua.unlocked_at
      FROM achievements a
      LEFT JOIN user_achievements ua ON a.id = ua.achievement_id AND ua.user_id = ?
      WHERE a.active = 1
    `).all(userId) as any[];

    return rows.map((r) => ({
      id: r.id,
      code: r.code,
      name: r.name,
      description: r.description,
      requirement: JSON.parse(r.requirement),
      xpReward: r.xp_reward,
      active: Boolean(r.active),
      unlockedAt: r.unlocked_at || undefined,
      isUnlocked: Boolean(r.unlocked_at)
    }));
  }
}
