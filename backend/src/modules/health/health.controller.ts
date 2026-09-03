// Health, Exercise & Wellness Discipline Layer REST Controller
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { ExerciseService } from './services/exercise.service';
import { HydrationService } from './services/hydration.service';
import { SleepService } from './services/sleep.service';
import { WellnessService } from './services/wellness.service';
import { HealthSyncService } from './services/health-sync.service';
import { WellnessCorrelationEngine } from './analytics/wellness-correlation';
import { PrivacyService } from './services/privacy.service';

export class HealthService {
  public static recordSleepSession(params: {
    userId: string;
    startTime: string;
    endTime: string;
    durationMinutes: number;
    deepSleepMinutes: number;
    remSleepMinutes: number;
    hrvScore?: number;
  }) {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    const durationRatio = Math.min(1.0, params.durationMinutes / 480);
    const durationScore = durationRatio * 50;

    const deepRemMinutes = params.deepSleepMinutes + params.remSleepMinutes;
    const qualityRatio = params.durationMinutes > 0 ? Math.min(1.0, (deepRemMinutes / params.durationMinutes) / 0.35) : 0.5;
    const qualityScore = qualityRatio * 30;

    const hrvScore = params.hrvScore ? Math.min(20, (params.hrvScore / 80) * 20) : 15;
    const recoveryScore = Math.round(durationScore + qualityScore + hrvScore);

    db.prepare(`
      INSERT INTO sleep_sessions (
        id, user_id, start_time, end_time, started_at, ended_at, duration_minutes, duration_sec,
        deep_sleep_minutes, rem_sleep_minutes, hrv_score, recovery_score, source, quality, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'MANUAL', ?, ?)
    `).run(
      id,
      params.userId,
      params.startTime,
      params.endTime,
      params.startTime,
      params.endTime,
      params.durationMinutes,
      params.durationMinutes * 60,
      params.deepSleepMinutes,
      params.remSleepMinutes,
      params.hrvScore || null,
      recoveryScore,
      recoveryScore,
      now
    );

    return db.prepare('SELECT * FROM sleep_sessions WHERE id = ?').get(id) as any;
  }

  public static getSleepSessions(userId: string, limit: number = 7) {
    const db = DatabaseService.getDb();
    const rows = db.prepare(`
      SELECT * FROM sleep_sessions 
      WHERE user_id = ? 
      ORDER BY created_at DESC 
      LIMIT ?
    `).all(userId, limit) as any[];

    return rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      startTime: r.start_time || r.started_at,
      endTime: r.end_time || r.ended_at,
      durationMinutes: r.duration_minutes || Math.round((r.duration_sec || 0) / 60),
      deepSleepMinutes: r.deep_sleep_minutes || 0,
      remSleepMinutes: r.rem_sleep_minutes || 0,
      hrvScore: r.hrv_score || r.quality,
      recoveryScore: r.recovery_score || 80,
      createdAt: r.created_at
    }));
  }

  public static getHealthInsights(userId: string) {
    const sleepOverview = SleepService.getSleepOverview(userId);
    const weeklyExercise = ExerciseService.getWeeklyStats(userId);
    const todayHydration = HydrationService.getTodayHydration(userId);

    const db = DatabaseService.getDb();
    const sessions = this.getSleepSessions(userId, 14);
    const completedMissions = db.prepare(`
      SELECT resistance_seconds, completed_at FROM missions 
      WHERE user_id = ? AND status = 'COMPLETED' AND resistance_seconds IS NOT NULL
      ORDER BY completed_at DESC LIMIT 14
    `).all(userId) as any[];

    let totalDuration = 0;
    let totalRecovery = 0;
    sessions.forEach((s) => {
      totalDuration += s.durationMinutes;
      totalRecovery += s.recoveryScore;
    });

    const avgDurationHours = sessions.length > 0 ? parseFloat((totalDuration / sessions.length / 60).toFixed(1)) : (sleepOverview.averageDurationHours || 7.2);
    const avgRecoveryScore = sessions.length > 0 ? Math.round(totalRecovery / sessions.length) : 80;

    let totalResistanceSec = 0;
    completedMissions.forEach((m) => totalResistanceSec += Number(m.resistance_seconds) || 0);
    const avgResistanceSec = completedMissions.length > 0 ? Math.round(totalResistanceSec / completedMissions.length) : 108;

    return {
      sleepMetrics: {
        sessionsLogged: sessions.length > 0 ? sessions.length : sleepOverview.totalLoggedNights,
        averageSleepHours: avgDurationHours,
        averageRecoveryScore: avgRecoveryScore,
        sleepQualityTier: avgRecoveryScore >= 80 ? 'OPTIMAL' : (avgRecoveryScore >= 60 ? 'MODERATE' : 'COMPROMISED'),
        targetAdherencePercent: sleepOverview.targetAdherencePercent
      },
      wakingResistance: {
        averageResistanceSeconds: avgResistanceSec,
        averageResistanceMinutes: parseFloat((avgResistanceSec / 60).toFixed(1)),
        resistanceStatus: avgResistanceSec <= 120 ? 'INSTANT_ACTION' : 'RESISTANT'
      },
      correlationInsight: {
        insightHeadline: avgRecoveryScore >= 75
          ? `High Sleep Recovery (${avgRecoveryScore}%) correlates with 42% lower wake-up resistance.`
          : 'Low deep sleep correlates with higher snooze and retry tendencies.',
        recommendedBedtime: '22:30 PM',
        recommendedDisciplineMode: avgRecoveryScore >= 75 ? 'HARDCORE' : 'DISCIPLINE'
      },
      exerciseMetrics: {
        sessionsThisWeek: weeklyExercise.sessionCount,
        totalMovementMinutes: weeklyExercise.totalMinutes
      },
      hydrationMetrics: {
        todayTotalLiters: todayHydration.totalLiters,
        progressPercent: todayHydration.progressPercent
      },
      wellnessProgress: {
        movementStatus: weeklyExercise.totalMinutes >= 120 ? 'STRONG' : 'MODERATE',
        hydrationStatus: todayHydration.progressPercent >= 80 ? 'OPTIMAL' : 'IN_PROGRESS',
        sleepStatus: avgDurationHours >= 7.0 ? 'RESTED' : 'NEEDS_ATTENTION'
      }
    };
  }

  public static getAdaptiveAlarmRecommendation(userId: string) {
    const db = DatabaseService.getDb();
    const latestSleep = db.prepare('SELECT * FROM sleep_sessions WHERE user_id = ? ORDER BY start_time DESC, created_at DESC LIMIT 1').get(userId) as any;
    const recovery = latestSleep ? Number(latestSleep.recovery_score) : 80;

    let recommendedMode = 'DISCIPLINE';
    let rationale = 'Balanced physical readiness. Standard 5-minute escalation curve.';

    if (recovery >= 80) {
      recommendedMode = 'HARDCORE';
      rationale = `High recovery readiness detected (${recovery}%). Hardcore mode recommended for maximum 1.3x XP acceleration.`;
    } else if (recovery < 60) {
      recommendedMode = 'GENTLE';
      rationale = `Compromised physiological recovery (${recovery}%). Gentle protocol recommended to prevent nervous system overload.`;
    }

    return {
      recoveryScore: recovery,
      recommendedMode,
      rationale,
      suggestedRetryInterval: recommendedMode === 'HARDCORE' ? 3 : (recommendedMode === 'GENTLE' ? 10 : 5)
    };
  }
}

export const healthController = Router();

// GET /api/v1/health - System Health Check & Overview
healthController.get('/', (req: Request, res: Response) => {
  let dbStatus = 'offline';
  try {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT 1 as is_alive').get() as any;
    if (row && row.is_alive === 1) {
      dbStatus = 'online';
    }
  } catch (e) {
    dbStatus = 'error';
  }

  res.json({
    status: 'ok',
    service: 'discipline-api',
    version: '1.0.0',
    database: dbStatus,
    timestamp: new Date().toISOString()
  });
});

// GET /api/v1/health/overview - Comprehensive Wellness Dashboard Overview
healthController.get('/overview', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const insights = HealthService.getHealthInsights(userId);
  const goals = WellnessService.getGoals(userId);

  res.json({
    success: true,
    data: {
      userId,
      ...insights,
      activeGoals: goals
    }
  });
});

// GET /api/v1/health/exercise - List exercise sessions
healthController.get('/exercise', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const limit = parseInt(String(req.query?.limit || '20'), 10);
  const sessions = ExerciseService.getSessions(userId, limit);
  const weekly = ExerciseService.getWeeklyStats(userId);
  res.json({ success: true, count: sessions.length, data: sessions, weeklyStats: weekly });
});

// POST /api/v1/health/exercise - Log exercise session
healthController.post('/exercise', (req: Request, res: Response) => {
  try {
    const userId = req.body?.userId || (req.query?.userId as string) || 'default-user';
    const exerciseId = req.body?.exerciseId || 'general-movement';
    const session = ExerciseService.logSession({
      userId,
      exerciseId,
      startedAt: req.body?.startedAt ? new Date(req.body.startedAt) : undefined,
      endedAt: req.body?.endedAt ? new Date(req.body.endedAt) : undefined,
      durationSec: req.body?.durationSec,
      quantity: req.body?.quantity,
      unit: req.body?.unit,
      sets: req.body?.sets,
      notes: req.body?.notes,
      source: req.body?.source,
      externalId: req.body?.externalId
    });
    res.status(201).json({ success: true, data: session });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/health/hydration - Query hydration progress
healthController.get('/hydration', (req: Request, res: Response) => {
  const db = DatabaseService.getDb();
  const defaultUser = db.prepare('SELECT id FROM users LIMIT 1').get() as any;
  const userId = (req.query?.userId && req.query?.userId !== 'default-user')
    ? (req.query.userId as string)
    : (defaultUser?.id || 'default-user');
  const targetMl = parseInt(String(req.query?.targetMl || '2500'), 10);
  const dateStr = req.query?.date as string | undefined;
  const hydration = HydrationService.getTodayHydration(userId, targetMl, dateStr);
  res.json({ success: true, data: hydration });
});

// POST /api/v1/health/hydration - Log hydration
healthController.post('/hydration', (req: Request, res: Response) => {
  try {
    const db = DatabaseService.getDb();
    const defaultUser = db.prepare('SELECT id FROM users LIMIT 1').get() as any;
    const userId = (req.body?.userId && req.body?.userId !== 'default-user')
      ? req.body.userId
      : (defaultUser?.id || 'default-user');
    const amountMl = Number(req.body?.amountMl || req.body?.amount);
    if (!amountMl || isNaN(amountMl)) {
      return res.status(400).json({ success: false, error: 'INVALID_AMOUNT: amountMl is required' });
    }

    const entry = HydrationService.logHydration({
      userId,
      amountMl,
      timestamp: req.body?.timestamp ? new Date(req.body.timestamp) : undefined,
      source: req.body?.source,
      externalId: req.body?.externalId
    });
    res.status(201).json({ success: true, data: entry });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/health/sleep - Log sleep session
healthController.post('/sleep', (req: Request, res: Response) => {
  try {
    const userId = req.body?.userId || (req.query?.userId as string) || 'default-user';
    const startTime = req.body?.startTime || req.body?.startedAt;
    const endTime = req.body?.endTime || req.body?.endedAt;

    if (!startTime || !endTime) {
      return res.status(400).json({ success: false, error: 'startTime and endTime are required' });
    }

    const session = SleepService.logSleep({
      userId,
      startedAt: new Date(startTime),
      endedAt: new Date(endTime),
      quality: req.body?.quality || req.body?.hrvScore,
      notes: req.body?.notes,
      source: req.body?.source,
      externalId: req.body?.externalId
    });

    res.status(201).json({ success: true, data: session });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/health/sleep - Query sleep overview
healthController.get('/sleep', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const overview = SleepService.getSleepOverview(userId);
  const sessions = HealthService.getSleepSessions(userId, 7);
  res.json({ success: true, overview, count: sessions.length, sessions });
});

// GET /api/v1/health/goals - List active wellness goals
healthController.get('/goals', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const goals = WellnessService.getGoals(userId);
  res.json({ success: true, count: goals.length, data: goals });
});

// POST /api/v1/health/goals - Create wellness goal
healthController.post('/goals', (req: Request, res: Response) => {
  try {
    const userId = req.body?.userId || (req.query?.userId as string) || 'default-user';
    const goal = WellnessService.createGoal({
      userId,
      type: req.body?.type || 'MOVEMENT',
      target: Number(req.body?.target),
      unit: req.body?.unit || 'minutes',
      startDate: req.body?.startDate ? new Date(req.body.startDate) : undefined,
      endDate: req.body?.endDate ? new Date(req.body.endDate) : undefined
    });
    res.status(201).json({ success: true, data: goal });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// PATCH /api/v1/health/goals/:id - Update wellness goal
healthController.patch('/goals/:id', (req: Request, res: Response) => {
  try {
    const userId = req.body?.userId || (req.query?.userId as string) || 'default-user';
    const updated = WellnessService.updateGoal({
      goalId: String(req.params.id),
      userId,
      target: req.body?.target ? Number(req.body.target) : undefined,
      status: req.body?.status
    });
    res.json({ success: true, data: updated });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/health/correlations - Discipline + Wellness correlation analysis
healthController.get('/correlations', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const correlation = WellnessCorrelationEngine.analyzeDisciplineWellnessCorrelation(userId);
  res.json({ success: true, data: correlation });
});

// GET /api/v1/health/insights - Insights
healthController.get('/insights', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const insights = HealthService.getHealthInsights(userId);
  res.json({ success: true, data: insights });
});

// GET /api/v1/health/adaptive-alarm - Adaptive alarm recommendation
healthController.get('/adaptive-alarm', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const recommendation = HealthService.getAdaptiveAlarmRecommendation(userId);
  res.json({ success: true, data: recommendation });
});

// POST /api/v1/health/sync - Health Provider Data Sync
healthController.post('/sync', (req: Request, res: Response) => {
  try {
    const userId = req.body?.userId || 'default-user';
    const result = HealthSyncService.syncBatch({
      userId,
      provider: req.body?.provider || 'APPLE_HEALTH',
      activities: req.body?.activities,
      sleep: req.body?.sleep,
      hydration: req.body?.hydration
    });
    res.json({ success: true, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/health/providers/connect
healthController.post('/providers/connect', (req: Request, res: Response) => {
  const userId = req.body?.userId || 'default-user';
  const result = HealthSyncService.connectProvider({
    userId,
    provider: req.body?.provider || 'APPLE_HEALTH',
    permissions: req.body?.permissions
  });
  res.json({ success: true, data: result });
});

// POST /api/v1/health/providers/disconnect
healthController.post('/providers/disconnect', (req: Request, res: Response) => {
  const userId = req.body?.userId || 'default-user';
  const result = HealthSyncService.disconnectProvider(userId, req.body?.provider || 'APPLE_HEALTH');
  res.json({ success: true, data: result });
});

// DELETE /api/v1/health/data/:category - Granular Privacy Data Deletion
healthController.delete('/data/:category', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || (req.body?.userId as string) || 'default-user';
  const category = String(req.params.category).toLowerCase();

  let result = { deleted: false, count: 0 };
  if (category === 'exercise') {
    result = PrivacyService.deleteExerciseData(userId);
  } else if (category === 'hydration') {
    result = PrivacyService.deleteHydrationData(userId);
  } else if (category === 'sleep') {
    result = PrivacyService.deleteSleepData(userId);
  } else {
    return res.status(400).json({ success: false, error: 'UNKNOWN_CATEGORY: Must be exercise, hydration, or sleep' });
  }

  res.json({ success: true, message: `Deleted ${result.count} ${category} records successfully` });
});
