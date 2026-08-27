// Authoritative Gamification Controller & Discipline Progress API
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { XpEngine } from './engine/xp-engine';
import { LevelEngine } from './engine/level-engine';
import { StreakEngine } from './engine/streak-engine';
import { ScoreEngine } from './engine/score-engine';
import { AchievementEngine } from './engine/achievement-engine';
import { RewardEngine } from './engine/reward-engine';

export class GamificationService {
  /**
   * Processes verified mission rewards, updates streaks, checks level progression & achievements
   */
  public static processMissionRewards(params: {
    userId: string;
    missionId: string;
    baseXp: number;
    difficulty?: number;
    resistanceSeconds?: number;
    attemptCount?: number;
    disciplineMode?: string;
    timezone?: string;
  }) {
    const db = DatabaseService.getDb();
    const streakRow = db.prepare('SELECT current_streak, grace_tokens FROM streaks WHERE user_id = ?').get(params.userId) as any;
    let currentStreak = streakRow?.current_streak || 0;
    let graceTokens = streakRow?.grace_tokens ?? 1;

    // 1. Calculate Reward Breakdown
    const reward = RewardEngine.calculateReward({
      baseXp: params.baseXp,
      difficulty: params.difficulty || 1,
      attemptCount: params.attemptCount || 1,
      resistanceSeconds: params.resistanceSeconds || 0,
      currentStreak
    });

    // 2. Check Idempotency for this Mission
    const existingTx = db.prepare("SELECT id FROM xp_transactions WHERE idempotency_key = ?").get(`MISSION_COMPLETED:${params.missionId}`) as any;
    const isDuplicate = Boolean(existingTx);

    if (!isDuplicate) {
      // Award Base XP
      XpEngine.awardXp({
        userId: params.userId,
        amount: reward.baseXp,
        sourceType: 'MISSION_COMPLETION',
        sourceId: params.missionId,
        reason: 'MISSION_COMPLETED',
        idempotencyKey: `MISSION_COMPLETED:${params.missionId}`
      });

      // Award Speed Bonus if applicable
      if (reward.speedBonus > 0) {
        XpEngine.awardXp({
          userId: params.userId,
          amount: reward.speedBonus,
          sourceType: 'MISSION_COMPLETION',
          sourceId: params.missionId,
          reason: 'FIRST_ATTEMPT_SPEED_BONUS',
          idempotencyKey: `SPEED_BONUS:${params.missionId}`
        });
      }

      // Update Streak
      currentStreak += 1;
      if (currentStreak % 14 === 0 && graceTokens < 3) {
        graceTokens += 1;
      }
      const now = new Date().toISOString();
      db.prepare(`
        INSERT OR REPLACE INTO streaks (user_id, current_streak, longest_streak, grace_tokens, last_completed_date, recovery_used, updated_at)
        VALUES (?, ?, ?, ?, ?, 0, ?)
      `).run(
        params.userId,
        currentStreak,
        Math.max(currentStreak, streakRow?.longest_streak || currentStreak),
        graceTokens,
        now.substring(0, 10),
        now
      );

      // Record Daily Stats & Score
      ScoreEngine.recordDailyStat(params.userId, now.substring(0, 10), reward.totalXp, true);
    }

    const totalXp = XpEngine.getTotalXp(params.userId);
    const levelResult = LevelEngine.syncUserLevel(params.userId, totalXp);
    const scoreResult = ScoreEngine.calculateDisciplineScore(params.userId, 30);
    const newAchievements = AchievementEngine.evaluateAchievements(params.userId);

    const updatedStreakRow = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(params.userId) as any;

    return {
      totalXp,
      baseXp: reward.baseXp,
      speedBonus: reward.speedBonus,
      streakBonus: reward.streakBonus,
      isDuplicate,
      level: levelResult.levelProgress,
      isLevelUp: levelResult.isLevelUp,
      streak: {
        current_streak: updatedStreakRow?.current_streak || currentStreak,
        longest_streak: updatedStreakRow?.longest_streak || currentStreak,
        grace_tokens: updatedStreakRow?.grace_tokens || graceTokens,
        recovery_used: Boolean(updatedStreakRow?.recovery_used)
      },
      disciplineScore: scoreResult.score,
      newAchievements
    };
  }

  /**
   * Retrieves unified gamification profile
   */
  public static getOverview(userId: string) {
    const totalXp = XpEngine.getTotalXp(userId);
    const levelProgress = LevelEngine.calculateLevel(totalXp);
    const db = DatabaseService.getDb();

    const streakRow = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(userId) as any;
    const currentStreak = streakRow?.current_streak || 0;
    const bestStreak = streakRow?.longest_streak || 0;
    const graceTokens = streakRow?.grace_tokens ?? 1;

    const scoreResult = ScoreEngine.calculateDisciplineScore(userId, 30);
    const achievements = this.getAchievements(userId);
    const completedCountRow = db.prepare("SELECT COUNT(*) as count FROM missions WHERE user_id = ? AND status = 'COMPLETED'").get(userId) as any;
    const completedCount = completedCountRow?.count || 0;

    return {
      user: { id: userId },
      user_id: userId,
      gamification: {
        totalXp,
        level: levelProgress.level,
        currentLevelBaseXp: levelProgress.currentLevelBaseXp,
        nextLevelBaseXp: levelProgress.nextLevelBaseXp,
        progressPercent: levelProgress.progressPercent,
        currentStreak,
        longestStreak: bestStreak,
        graceTokens,
        disciplineScore: scoreResult.score,
        completedMissionsCount: completedCount,
        tasksCompleted: completedCount
      },
      streaks: {
        currentStreak,
        longestStreak: bestStreak,
        graceTokens
      },
      levelProgress,
      disciplineScore: scoreResult,
      achievements
    };
  }

  public static getAchievements(userId: string) {
    const db = DatabaseService.getDb();
    const completedCountRow = db.prepare("SELECT COUNT(*) as count FROM missions WHERE user_id = ? AND status = 'COMPLETED'").get(userId) as any;
    const completedCount = completedCountRow?.count || 0;

    const streakRow = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(userId) as any;
    const currentStreak = streakRow?.current_streak || 0;
    const graceTokens = streakRow?.grace_tokens ?? 1;

    const speedBonusCountRow = db.prepare("SELECT COUNT(*) as count FROM xp_transactions WHERE user_id = ? AND reason = 'FIRST_ATTEMPT_SPEED_BONUS'").get(userId) as any;
    const speedBonusCount = speedBonusCountRow?.count || 0;

    const now = new Date().toISOString();

    return [
      {
        id: 'first_mission',
        code: 'FIRST_STEP',
        name: 'First Step to Order',
        description: 'Complete your first morning discipline mission.',
        category: 'MASTERY',
        icon: 'shield_moon',
        xpReward: 50,
        isUnlocked: completedCount >= 1,
        unlockedAt: completedCount >= 1 ? now : undefined
      },
      {
        id: 'streak_7',
        code: 'FIRST_7_DAY_STREAK',
        name: '7-Day Iron Will',
        description: 'Maintain an unbroken 7-day discipline streak.',
        category: 'STREAK',
        icon: 'local_fire_department',
        xpReward: 100,
        isUnlocked: currentStreak >= 7,
        unlockedAt: currentStreak >= 7 ? now : undefined
      },
      {
        id: 'streak_30',
        code: 'FIRST_30_DAY_STREAK',
        name: '30-Day Spartan',
        description: 'Complete 30 consecutive days without breaking discipline.',
        category: 'STREAK',
        icon: 'military_tech',
        xpReward: 500,
        isUnlocked: currentStreak >= 30,
        unlockedAt: currentStreak >= 30 ? now : undefined
      },
      {
        id: 'zero_hesitation',
        code: 'ZERO_HESITATION',
        name: 'Zero Hesitation',
        description: 'Earn 5 Instant Action Speed Bonuses (under 120s resistance).',
        category: 'SPEED',
        icon: 'bolt',
        xpReward: 150,
        isUnlocked: speedBonusCount >= 5,
        unlockedAt: speedBonusCount >= 5 ? now : undefined
      },
      {
        id: 'grace_guardian',
        code: 'GRACE_GUARDIAN',
        name: 'Grace Vault Guardian',
        description: 'Accumulate the maximum capacity of 3 Grace Tokens.',
        category: 'DEFENSE',
        icon: 'security',
        xpReward: 75,
        isUnlocked: graceTokens >= 3,
        unlockedAt: graceTokens >= 3 ? now : undefined
      }
    ];
  }

  public static getLedger(userId: string, limit: number = 50, offset: number = 0) {
    const db = DatabaseService.getDb();
    const rows = db.prepare(`
      SELECT id, mission_id, amount, reason, source_type, created_at 
      FROM xp_transactions 
      WHERE user_id = ? 
      ORDER BY created_at DESC 
      LIMIT ? OFFSET ?
    `).all(userId, limit, offset) as any[];

    const totalXp = XpEngine.getTotalXp(userId);

    return {
      totalXp,
      count: rows.length,
      transactions: rows.map((r) => ({
        id: r.id,
        missionId: r.mission_id,
        amount: r.amount,
        formattedAmount: r.amount >= 0 ? `+${r.amount} XP` : `${r.amount} XP`,
        reason: r.reason,
        sourceType: r.source_type,
        createdAt: r.created_at
      }))
    };
  }

  public static getSummary(userId: string, period: 'daily' | 'weekly' | 'monthly') {
    const db = DatabaseService.getDb();
    const days = period === 'daily' ? 1 : period === 'weekly' ? 7 : 30;
    const now = new Date();
    const startDate = new Date(now.getTime() - days * 24 * 60 * 60 * 1000).toISOString().substring(0, 10);

    const statsRows = db.prepare(`
      SELECT date, tasks_assigned, tasks_completed, tasks_failed, xp_earned, discipline_score
      FROM daily_discipline_stats
      WHERE user_id = ? AND date >= ?
      ORDER BY date ASC
    `).all(userId, startDate) as any[];

    const totalCompleted = statsRows.reduce((acc, r) => acc + (r.tasks_completed || 0), 0);
    const totalAssigned = statsRows.reduce((acc, r) => acc + (r.tasks_assigned || 0), 0);
    const totalXp = statsRows.reduce((acc, r) => acc + (r.xp_earned || 0), 0);
    const completionRate = totalAssigned > 0 ? Math.round((totalCompleted / totalAssigned) * 100) : 100;

    const streakRow = db.prepare('SELECT current_streak FROM streaks WHERE user_id = ?').get(userId) as any;

    return {
      period,
      startDate,
      tasksCompleted: totalCompleted,
      tasksAttempted: totalAssigned,
      completionRate,
      currentStreak: streakRow?.current_streak || 0,
      xpEarned: totalXp,
      dailyBreakdown: statsRows
    };
  }
}

export const gamificationController = Router();

// GET /api/v1/gamification/profile
gamificationController.get('/profile', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const overview = GamificationService.getOverview(userId);
  res.json({ success: true, data: overview });
});

// GET /api/v1/gamification/overview
gamificationController.get('/overview', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const overview = GamificationService.getOverview(userId);
  res.json({ success: true, data: overview });
});

// GET /api/v1/gamification/xp
gamificationController.get('/xp', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const ledger = GamificationService.getLedger(userId);
  res.json({ success: true, data: ledger });
});

// GET /api/v1/gamification/ledger
gamificationController.get('/ledger', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const ledger = GamificationService.getLedger(userId);
  res.json({ success: true, data: ledger });
});

// GET /api/v1/gamification/level
gamificationController.get('/level', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const totalXp = XpEngine.getTotalXp(userId);
  const levelProgress = LevelEngine.calculateLevel(totalXp);
  res.json({ success: true, data: levelProgress });
});

// GET /api/v1/gamification/streak
gamificationController.get('/streak', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const db = DatabaseService.getDb();
  const streak = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(userId) as any;
  res.json({ success: true, data: streak || { current_streak: 0, longest_streak: 0, grace_tokens: 1 } });
});

// POST /api/v1/gamification/streak/recover
gamificationController.post('/streak/recover', (req: Request, res: Response) => {
  try {
    const userId = req.body?.userId || 'default-user';
    const result = StreakEngine.recoverStreak(userId);
    res.json({ success: true, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/gamification/score
gamificationController.get('/score', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const score = ScoreEngine.calculateDisciplineScore(userId, 30);
  res.json({ success: true, data: score });
});

// GET /api/v1/gamification/achievements
gamificationController.get('/achievements', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const achievements = GamificationService.getAchievements(userId);
  res.json({ success: true, data: achievements });
});

// GET /api/v1/gamification/summary/daily
gamificationController.get('/summary/daily', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const summary = GamificationService.getSummary(userId, 'daily');
  res.json({ success: true, data: summary });
});

// GET /api/v1/gamification/summary/weekly
gamificationController.get('/summary/weekly', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const summary = GamificationService.getSummary(userId, 'weekly');
  res.json({ success: true, data: summary });
});

// GET /api/v1/gamification/summary/monthly
gamificationController.get('/summary/monthly', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const summary = GamificationService.getSummary(userId, 'monthly');
  res.json({ success: true, data: summary });
});
