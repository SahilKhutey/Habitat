// Gamification Service & Controller (XP Ledger, Streaks, Levels & Achievements)
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';

export class GamificationService {
  public static processMissionRewards(params: {
    userId: string;
    missionId: string;
    baseXp: number;
    resistanceSeconds: number;
    attemptCount: number;
    disciplineMode: string;
  }) {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    const resistanceMin = params.resistanceSeconds / 60.0;

    // 1. Calculate Base XP and Multipliers
    let speedBonus = 0;
    if (params.attemptCount === 1 && resistanceMin <= 2.0) {
      speedBonus = Math.round(params.baseXp * 0.5); // +50% Instant Action Bonus
    }

    const totalXp = params.baseXp + speedBonus;

    // 2. Append XP Transactions to Ledger
    db.prepare(`
      INSERT INTO xp_transactions (id, user_id, mission_id, amount, reason, created_at)
      VALUES (?, ?, ?, ?, 'MISSION_COMPLETED', ?)
    `).run(uuidv4(), params.userId, params.missionId, params.baseXp, now);

    if (speedBonus > 0) {
      db.prepare(`
        INSERT INTO xp_transactions (id, user_id, mission_id, amount, reason, created_at)
        VALUES (?, ?, ?, ?, 'FIRST_ATTEMPT_SPEED_BONUS', ?)
      `).run(uuidv4(), params.userId, params.missionId, speedBonus, now);
    }

    // 3. Update Streak & Grace Tokens
    const streakRow = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(params.userId) as any;
    let currentStreak = streakRow ? streakRow.current_streak + 1 : 1;
    let longestStreak = streakRow ? Math.max(streakRow.longest_streak, currentStreak) : 1;
    let graceTokens = streakRow ? streakRow.grace_tokens : 1;

    // Earn 1 grace token every 14 days (Max 3 tokens)
    if (currentStreak % 14 === 0 && graceTokens < 3) {
      graceTokens += 1;
    }

    db.prepare(`
      INSERT OR REPLACE INTO streaks (user_id, current_streak, longest_streak, grace_tokens, last_completed_date, updated_at)
      VALUES (?, ?, ?, ?, ?, ?)
    `).run(params.userId, currentStreak, longestStreak, graceTokens, now.substring(0, 10), now);

    return {
      totalXp,
      baseXp: params.baseXp,
      speedBonus,
      streak: { current_streak: currentStreak, longest_streak: longestStreak, grace_tokens: graceTokens }
    };
  }

  public static getLedger(userId: string, limit: number = 50, offset: number = 0) {
    const db = DatabaseService.getDb();
    const rows = db.prepare(`
      SELECT id, mission_id, amount, reason, created_at 
      FROM xp_transactions 
      WHERE user_id = ? 
      ORDER BY created_at DESC 
      LIMIT ? OFFSET ?
    `).all(userId, limit, offset) as any[];

    const sumRow = db.prepare('SELECT SUM(amount) as total FROM xp_transactions WHERE user_id = ?').get(userId) as any;

    return {
      totalXp: sumRow?.total ?? 0,
      count: rows.length,
      transactions: rows.map((r) => ({
        id: r.id,
        missionId: r.mission_id,
        amount: r.amount,
        formattedAmount: r.amount >= 0 ? `+${r.amount} XP` : `${r.amount} XP`,
        reason: r.reason,
        createdAt: r.created_at
      }))
    };
  }

  public static getAchievements(userId: string) {
    const db = DatabaseService.getDb();
    const streakRow = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(userId) as any;
    const xpSum = db.prepare('SELECT SUM(amount) as total FROM xp_transactions WHERE user_id = ?').get(userId) as any;
    const completedCountRow = db.prepare("SELECT COUNT(*) as count FROM missions WHERE user_id = ? AND status = 'COMPLETED'").get(userId) as any;
    const fastCountRow = db.prepare("SELECT COUNT(*) as count FROM xp_transactions WHERE user_id = ? AND reason = 'FIRST_ATTEMPT_SPEED_BONUS'").get(userId) as any;

    const currentStreak = streakRow?.current_streak ?? 0;
    const totalXp = xpSum?.total ?? 0;
    const completedCount = completedCountRow?.count ?? 0;
    const fastCount = fastCountRow?.count ?? 0;

    const achievements = [
      {
        id: 'first_mission',
        title: 'First Step to Order',
        description: 'Complete your first physical wakeup mission.',
        icon: 'verified',
        isUnlocked: completedCount >= 1,
        unlockedAt: completedCount >= 1 ? 'Unlocked' : null
      },
      {
        id: 'speed_demon',
        title: 'Instant Action',
        description: 'Complete a mission in under 120 seconds on first attempt.',
        icon: 'flash_on',
        isUnlocked: fastCount >= 1,
        unlockedAt: fastCount >= 1 ? 'Unlocked' : null
      },
      {
        id: 'streak_5',
        title: '5-Day Momentum',
        description: 'Maintain 5 consecutive days of mission execution.',
        icon: 'local_fire_department',
        isUnlocked: currentStreak >= 5,
        unlockedAt: currentStreak >= 5 ? 'Unlocked' : null
      },
      {
        id: 'streak_14',
        title: 'Grace Vault Master',
        description: 'Reach a 14-day streak to earn a bonus Grace Token.',
        icon: 'shield',
        isUnlocked: currentStreak >= 14,
        unlockedAt: currentStreak >= 14 ? 'Unlocked' : null
      },
      {
        id: 'xp_1000',
        title: 'Habit Disciple (1K XP)',
        description: 'Accumulate 1,000+ XP in the immutable ledger.',
        icon: 'military_tech',
        isUnlocked: totalXp >= 1000,
        unlockedAt: totalXp >= 1000 ? 'Unlocked' : null
      }
    ];

    return achievements;
  }

  public static getOverview(userId: string) {
    const db = DatabaseService.getDb();
    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(userId) as any;
    const streak = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(userId) as any;
    const xpSum = db.prepare('SELECT SUM(amount) as total FROM xp_transactions WHERE user_id = ?').get(userId) as any;

    const completedMissions = db.prepare(`
      SELECT resistance_seconds, completed_at FROM missions 
      WHERE user_id = ? AND status = 'COMPLETED'
      ORDER BY completed_at DESC LIMIT 30
    `).all(userId) as any[];

    let totalSec = 0;
    completedMissions.forEach((m) => totalSec += (m.resistance_seconds || 0));
    const avgResistanceMin = completedMissions.length > 0 ? parseFloat((totalSec / completedMissions.length / 60).toFixed(2)) : 0;

    const totalXp = xpSum?.total ?? 0;
    // Level formula: Level 1 at 0 XP, Level 2 at 100 XP, Level 3 at 400 XP, Level 4 at 900 XP, Level 5 at 1600 XP...
    const currentLevel = Math.min(10, Math.floor(Math.sqrt(totalXp / 100)) + 1);
    const nextLevelXp = Math.pow(currentLevel, 2) * 100;

    return {
      user: {
        id: user?.id,
        displayName: user?.display_name,
        disciplineScore: user?.discipline_score ?? 100,
        autonomyLevel: user?.autonomy_level ?? 1
      },
      streaks: {
        currentStreak: streak?.current_streak ?? 0,
        longestStreak: streak?.longest_streak ?? 0,
        graceTokens: streak?.grace_tokens ?? 1
      },
      gamification: {
        totalXp,
        level: currentLevel,
        nextLevelXp,
        averageResistanceMinutes: avgResistanceMin,
        completedMissionsCount: completedMissions.length
      }
    };
  }
}

export const gamificationController = Router();

// GET /api/v1/gamification/overview
gamificationController.get('/overview', (req: Request, res: Response) => {
  const db = DatabaseService.getDb();
  const defaultUser = db.prepare('SELECT id FROM users LIMIT 1').get() as any;
  const userId = (req.query.userId as string) || defaultUser?.id;

  if (!userId) {
    res.status(400).json({ success: false, error: 'User ID required' });
    return;
  }

  const overview = GamificationService.getOverview(userId);
  res.json({ success: true, data: overview });
});

// GET /api/v1/gamification/ledger
gamificationController.get('/ledger', (req: Request, res: Response) => {
  const db = DatabaseService.getDb();
  const defaultUser = db.prepare('SELECT id FROM users LIMIT 1').get() as any;
  const userId = (req.query.userId as string) || defaultUser?.id;
  const limit = parseInt(req.query.limit as string || '50', 10);
  const offset = parseInt(req.query.offset as string || '0', 10);

  const ledger = GamificationService.getLedger(userId, limit, offset);
  res.json({ success: true, data: ledger });
});

// GET /api/v1/gamification/achievements
gamificationController.get('/achievements', (req: Request, res: Response) => {
  const db = DatabaseService.getDb();
  const defaultUser = db.prepare('SELECT id FROM users LIMIT 1').get() as any;
  const userId = (req.query.userId as string) || defaultUser?.id;

  const achievements = GamificationService.getAchievements(userId);
  res.json({ success: true, count: achievements.length, data: achievements });
});
