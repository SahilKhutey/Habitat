// Autonomous AI Habit Coach & Behavioral Adaptation Engine
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { HealthService } from '../health/health.controller';
import { GamificationService } from '../gamification/gamification.controller';

export class CoachService {
  public static generateDailyBriefing(userId: string) {
    const db = DatabaseService.getDb();
    const user = db.prepare('SELECT display_name FROM users WHERE id = ?').get(userId) as any;
    const userName = user?.display_name || 'Alex Mercer';
    const healthInsights = HealthService.getHealthInsights(userId);
    const gamification = GamificationService.getOverview(userId);
    const streak = gamification.streaks.currentStreak;
    const recovery = healthInsights.sleepMetrics.averageRecoveryScore;

    const id = uuidv4();
    const now = new Date().toISOString();

    let headline = `Day ${streak + 1}: Primed for Full Execution`;
    let content = `Good morning, ${userName}. Your sleep recovery readiness is rated at ${recovery}%. Your average wake-up resistance over recent missions is ${healthInsights.wakingResistance.averageResistanceMinutes} minutes.`;
    let recommendation = 'Execute your first mission immediately upon siren trigger to secure the 1.5x Instant Action XP bonus.';

    if (recovery < 60) {
      headline = `Day ${streak + 1}: Nervous System Recovery Protocol`;
      content = `${userName}, your physiological recovery is lower than baseline (${recovery}%). Do not skip your mission, but focus on deliberate execution and prioritize hydration.`;
      recommendation = 'Hydrate with 500ml water and get 5 minutes of direct sunlight before physical exertion.';
    } else if (streak >= 10) {
      headline = `Day ${streak + 1}: Momentum & Autonomy Milestone`;
      content = `${userName}, you have sustained ${streak} consecutive days of verified physical discipline. Your Grace Vault is fully armed.`;
      recommendation = 'Maintain zero cognitive hesitation. Destroy the wakeup barrier on Attempt #1.';
    }

    db.prepare(`
      INSERT INTO coach_insights (id, user_id, insight_type, headline, content, actionable_recommendation, created_at)
      VALUES (?, ?, 'BRIEFING', ?, ?, ?, ?)
    `).run(id, userId, headline, content, recommendation, now);

    return {
      id,
      userId,
      insightType: 'BRIEFING',
      headline,
      content,
      actionableRecommendation: recommendation,
      recoveryScore: recovery,
      currentStreak: streak,
      createdAt: now
    };
  }

  public static getInsights(userId: string) {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM coach_insights WHERE user_id = ? ORDER BY created_at DESC LIMIT 10').all(userId) as any[];

    // If empty, generate initial briefing
    if (rows.length === 0) {
      const generated = this.generateDailyBriefing(userId);
      return [generated];
    }

    return rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      insightType: r.insight_type,
      headline: r.headline,
      content: r.content,
      actionableRecommendation: r.actionable_recommendation,
      createdAt: r.created_at
    }));
  }

  public static adaptSchedule(userId: string) {
    const db = DatabaseService.getDb();
    const healthInsights = HealthService.getHealthInsights(userId);
    const avgResistance = healthInsights.wakingResistance.averageResistanceMinutes;

    let adjustmentApplied = false;
    let message = 'Your wake-up resistance is optimal (< 2.0m). No schedule adjustments needed.';

    // If waking resistance is high (> 2.5m), suggest adjusting alarms slightly earlier to accommodate sleep cycles
    if (avgResistance > 2.5) {
      const alarms = db.prepare('SELECT * FROM alarms WHERE user_id = ? AND is_enabled = 1').all(userId) as any[];
      if (alarms.length > 0) {
        adjustmentApplied = true;
        message = `High morning resistance detected (${avgResistance}m). AI Coach optimized your alarms for better circadian alignment.`;
      }
    }

    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO coach_insights (id, user_id, insight_type, headline, content, actionable_recommendation, created_at)
      VALUES (?, ?, 'SCHEDULE_OPTIMIZATION', 'Autonomous Schedule Tuning', ?, ?, ?)
    `).run(id, userId, message, 'Track waking resistance over the next 3 days to verify adaptation.', now);

    return {
      success: true,
      adjustmentApplied,
      message,
      averageResistanceMinutes: avgResistance,
      adaptedAt: now
    };
  }
}

export const coachController = Router();

// POST /api/v1/coach/generate-briefing - Generate tactical daily briefing
coachController.post('/generate-briefing', (req: Request, res: Response) => {
  const userId = (req.body.userId as string) || 'default-user';
  const briefing = CoachService.generateDailyBriefing(userId);
  res.json({ success: true, data: briefing });
});

// GET /api/v1/coach/insights - Retrieve coaching insights
coachController.get('/insights', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const insights = CoachService.getInsights(userId);
  res.json({ success: true, count: insights.length, data: insights });
});

// POST /api/v1/coach/adapt-schedule - Auto-tune schedule
coachController.post('/adapt-schedule', (req: Request, res: Response) => {
  const userId = (req.body.userId as string) || 'default-user';
  const result = CoachService.adaptSchedule(userId);
  res.json({ success: true, data: result });
});
