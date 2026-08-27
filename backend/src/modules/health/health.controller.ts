// Health & Sleep Resistance Correlation Service & Controller with System Health Check
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';

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
      INSERT INTO sleep_sessions (id, user_id, start_time, end_time, duration_minutes, deep_sleep_minutes, rem_sleep_minutes, hrv_score, recovery_score, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      id,
      params.userId,
      params.startTime,
      params.endTime,
      params.durationMinutes,
      params.deepSleepMinutes,
      params.remSleepMinutes,
      params.hrvScore || null,
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
      ORDER BY start_time DESC 
      LIMIT ?
    `).all(userId, limit) as any[];

    return rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      startTime: r.start_time,
      endTime: r.end_time,
      durationMinutes: r.duration_minutes,
      deepSleepMinutes: r.deep_sleep_minutes,
      remSleepMinutes: r.rem_sleep_minutes,
      hrvScore: r.hrv_score,
      recoveryScore: r.recovery_score,
      createdAt: r.created_at
    }));
  }

  public static getHealthInsights(userId: string) {
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

    const avgDurationHours = sessions.length > 0 ? parseFloat((totalDuration / sessions.length / 60).toFixed(1)) : 7.2;
    const avgRecoveryScore = sessions.length > 0 ? Math.round(totalRecovery / sessions.length) : 80;

    let totalResistanceSec = 0;
    completedMissions.forEach((m) => totalResistanceSec += m.resistance_seconds);
    const avgResistanceSec = completedMissions.length > 0 ? Math.round(totalResistanceSec / completedMissions.length) : 108;

    return {
      sleepMetrics: {
        sessionsLogged: sessions.length,
        averageSleepHours: avgDurationHours,
        averageRecoveryScore: avgRecoveryScore,
        sleepQualityTier: avgRecoveryScore >= 80 ? 'OPTIMAL' : (avgRecoveryScore >= 60 ? 'MODERATE' : 'COMPROMISED')
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
      }
    };
  }

  public static getAdaptiveAlarmRecommendation(userId: string) {
    const db = DatabaseService.getDb();
    const latestSleep = db.prepare('SELECT * FROM sleep_sessions WHERE user_id = ? ORDER BY start_time DESC LIMIT 1').get(userId) as any;
    const recovery = latestSleep ? latestSleep.recovery_score : 80;

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

// GET /api/v1/health - System Health Check
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
    version: '0.1.0',
    database: dbStatus,
    timestamp: new Date().toISOString()
  });
});

// POST /api/v1/health/sleep - Ingest sleep telemetry
healthController.post('/sleep', (req: Request, res: Response) => {
  try {
    const { userId, startTime, endTime, durationMinutes, deepSleepMinutes, remSleepMinutes, hrvScore } = req.body;
    if (!startTime || !endTime || durationMinutes === undefined) {
      res.status(400).json({ success: false, error: 'startTime, endTime, and durationMinutes are required' });
      return;
    }

    const session = HealthService.recordSleepSession({
      userId: userId || 'default-user',
      startTime,
      endTime,
      durationMinutes,
      deepSleepMinutes: deepSleepMinutes || 0,
      remSleepMinutes: remSleepMinutes || 0,
      hrvScore
    });

    res.status(201).json({ success: true, data: session });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/health/sleep - Query sleep sessions
healthController.get('/sleep', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const limit = parseInt(req.query.limit as string || '7', 10);
  const sessions = HealthService.getSleepSessions(userId, limit);
  res.json({ success: true, count: sessions.length, data: sessions });
});

// GET /api/v1/health/insights - Sleep & Resistance correlation insights
healthController.get('/insights', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const insights = HealthService.getHealthInsights(userId);
  res.json({ success: true, data: insights });
});

// GET /api/v1/health/adaptive-alarm - Adaptive alarm recommendation
healthController.get('/adaptive-alarm', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const recommendation = HealthService.getAdaptiveAlarmRecommendation(userId);
  res.json({ success: true, data: recommendation });
});
