// Mission Engine Service & Controller with Full State Machine & Escalation Loop
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { ProofsService } from '../proofs/proofs.controller';
import { GamificationService } from '../gamification/gamification.controller';

export class MissionsService {
  public static triggerMission(params: {
    userId: string;
    alarmId?: string;
    taskId: string;
    disciplineMode?: string;
    scheduledAt?: string;
    idempotencyKey?: string;
  }) {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    const scheduledAt = params.scheduledAt || now;

    // 1. Idempotency Check
    if (params.idempotencyKey) {
      const existing = db.prepare('SELECT * FROM missions WHERE idempotency_key = ?').get(params.idempotencyKey) as any;
      if (existing) {
        return this.getById(existing.id);
      }
    }

    const missionId = uuidv4();
    const mode = params.disciplineMode || 'DISCIPLINE';

    // 2. Create Mission Record
    db.prepare(`
      INSERT INTO missions (id, user_id, alarm_id, task_id, scheduled_at, triggered_at, status, attempt_count, discipline_mode, idempotency_key, created_at)
      VALUES (?, ?, ?, ?, ?, ?, 'TRIGGERED', 1, ?, ?, ?)
    `).run(
      missionId,
      params.userId,
      params.alarmId || null,
      params.taskId,
      scheduledAt,
      now,
      mode,
      params.idempotencyKey || null,
      now
    );

    // 3. Create Attempt #1 (Initial Siren Volume: 70)
    db.prepare(`
      INSERT INTO mission_attempts (id, mission_id, attempt_index, triggered_at, status, siren_volume_level)
      VALUES (?, ?, 1, ?, 'TRIGGERED', 70)
    `).run(uuidv4(), missionId, now);

    return this.getById(missionId);
  }

  public static startMission(missionId: string) {
    const db = DatabaseService.getDb();
    const mission = this.getById(missionId);
    if (!mission) throw new Error('Mission not found');

    if (mission.status === 'COMPLETED') {
      return mission;
    }

    db.prepare("UPDATE missions SET status = 'ACTIVE' WHERE id = ?").run(missionId);
    return this.getById(missionId);
  }

  public static retryMission(missionId: string) {
    const db = DatabaseService.getDb();
    const mission = this.getById(missionId);
    if (!mission) throw new Error('Mission not found');
    if (mission.status === 'COMPLETED') throw new Error('Cannot retry completed mission');

    const nextAttemptIndex = (mission.attemptCount || 1) + 1;
    const now = new Date().toISOString();

    // Volume Escalation Curve: Attempt 1=70, Attempt 2=85, Attempt 3+=100
    let sirenVolume = 70;
    if (nextAttemptIndex === 2) sirenVolume = 85;
    if (nextAttemptIndex >= 3) sirenVolume = 100;

    // Update Mission status to RETRYING and increment attempt count
    db.prepare(`
      UPDATE missions 
      SET status = 'RETRYING', attempt_count = ? 
      WHERE id = ?
    `).run(nextAttemptIndex, missionId);

    // Record New Escalated Attempt
    db.prepare(`
      INSERT INTO mission_attempts (id, mission_id, attempt_index, triggered_at, status, siren_volume_level)
      VALUES (?, ?, ?, ?, 'TRIGGERED', ?)
    `).run(uuidv4(), missionId, nextAttemptIndex, now, sirenVolume);

    return this.getById(missionId);
  }

  public static completeMission(missionId: string, customProofResult?: any) {
    const db = DatabaseService.getDb();
    const mission = this.getById(missionId);
    if (!mission) throw new Error('Mission not found');
    if (mission.status === 'COMPLETED') return mission;

    const now = new Date();
    const scheduled = new Date(mission.scheduledAt);
    const resistanceSeconds = Math.max(0, Math.floor((now.getTime() - scheduled.getTime()) / 1000));

    // 1. Mark Mission COMPLETED
    db.prepare(`
      UPDATE missions 
      SET status = 'COMPLETED', completed_at = ?, resistance_seconds = ?
      WHERE id = ?
    `).run(now.toISOString(), resistanceSeconds, missionId);

    // 2. Resolve Latest Attempt
    db.prepare(`
      UPDATE mission_attempts 
      SET status = 'COMPLETED', resolved_at = ? 
      WHERE mission_id = ? AND status != 'COMPLETED'
    `).run(now.toISOString(), missionId);

    // 3. Process Gamification Rewards (XP & Streaks)
    const taskRow = db.prepare('SELECT * FROM tasks WHERE id = ?').get(mission.taskId) as any;
    const baseXp = taskRow?.base_xp || 50;

    GamificationService.processMissionRewards({
      userId: mission.userId,
      missionId,
      baseXp,
      resistanceSeconds,
      attemptCount: mission.attemptCount || 1,
      disciplineMode: mission.disciplineMode || 'DISCIPLINE'
    });

    return this.getById(missionId);
  }

  public static expireMission(missionId: string) {
    const db = DatabaseService.getDb();
    db.prepare("UPDATE missions SET status = 'FAILED' WHERE id = ?").run(missionId);
    return this.getById(missionId);
  }

  public static getAttempts(missionId: string) {
    const db = DatabaseService.getDb();
    return db.prepare(`
      SELECT * FROM mission_attempts 
      WHERE mission_id = ? 
      ORDER BY attempt_index ASC
    `).all(missionId) as any[];
  }

  public static getToday(userId: string) {
    const db = DatabaseService.getDb();
    const rows = db.prepare(`
      SELECT 
        m.id, m.user_id, m.alarm_id, m.task_id, m.scheduled_at, m.triggered_at, 
        m.completed_at, m.status, m.attempt_count, m.resistance_seconds, m.discipline_mode,
        t.title as task_title, t.category as task_category, t.proof_type as task_proof_type,
        t.base_xp as task_base_xp, t.icon_name as task_icon_name
      FROM missions m
      JOIN tasks t ON m.task_id = t.id
      WHERE m.user_id = ?
      ORDER BY m.scheduled_at ASC
    `).all(userId) as any[];

    return rows.map(this.mapToMission);
  }

  public static getActive(userId: string) {
    const db = DatabaseService.getDb();
    const row = db.prepare(`
      SELECT 
        m.id, m.user_id, m.alarm_id, m.task_id, m.scheduled_at, m.triggered_at, 
        m.completed_at, m.status, m.attempt_count, m.resistance_seconds, m.discipline_mode,
        t.title as task_title, t.category as task_category, t.proof_type as task_proof_type,
        t.base_xp as task_base_xp, t.icon_name as task_icon_name
      FROM missions m
      JOIN tasks t ON m.task_id = t.id
      WHERE m.user_id = ? AND m.status IN ('TRIGGERED', 'ACTIVE', 'RETRYING')
      ORDER BY m.triggered_at DESC
      LIMIT 1
    `).get(userId) as any;

    if (!row) return null;
    return this.mapToMission(row);
  }

  public static getById(id: string) {
    const db = DatabaseService.getDb();
    const row = db.prepare(`
      SELECT 
        m.id, m.user_id, m.alarm_id, m.task_id, m.scheduled_at, m.triggered_at, 
        m.completed_at, m.status, m.attempt_count, m.resistance_seconds, m.discipline_mode,
        t.title as task_title, t.category as task_category, t.proof_type as task_proof_type,
        t.base_xp as task_base_xp, t.icon_name as task_icon_name
      FROM missions m
      JOIN tasks t ON m.task_id = t.id
      WHERE m.id = ?
    `).get(id) as any;

    if (!row) return null;
    return this.mapToMission(row);
  }

  public static getAll(userId?: string) {
    const db = DatabaseService.getDb();
    let query = `
      SELECT 
        m.id, m.user_id, m.alarm_id, m.task_id, m.scheduled_at, m.triggered_at, 
        m.completed_at, m.status, m.attempt_count, m.resistance_seconds, m.discipline_mode,
        t.title as task_title, t.category as task_category, t.proof_type as task_proof_type,
        t.base_xp as task_base_xp, t.icon_name as task_icon_name
      FROM missions m
      LEFT JOIN tasks t ON m.task_id = t.id
    `;
    const params: any[] = [];
    if (userId) {
      query += ' WHERE m.user_id = ?';
      params.push(userId);
    }
    query += ' ORDER BY m.created_at DESC LIMIT 50';
    const rows = db.prepare(query).all(...params) as any[];
    return rows.map(this.mapToMission);
  }

  private static mapToMission(row: any) {
    return {
      id: row.id,
      userId: row.user_id,
      alarmId: row.alarm_id,
      taskId: row.task_id,
      taskTitle: row.task_title,
      taskCategory: row.task_category,
      taskProofType: row.task_proof_type,
      taskBaseXp: row.task_base_xp,
      taskIconName: row.task_icon_name,
      scheduledAt: row.scheduled_at,
      triggeredAt: row.triggered_at,
      completedAt: row.completed_at,
      status: row.status,
      attemptCount: row.attempt_count,
      resistanceSeconds: row.resistance_seconds,
      disciplineMode: row.discipline_mode
    };
  }
}

import { authGuard, AuthenticatedRequest } from '../../common/guards/auth.guard';

export const missionsController = Router();

// GET /api/v1/missions - List all missions (public or authenticated)
missionsController.get('/', (req: Request, res: Response) => {
  const db = DatabaseService.getDb();
  const defaultUser = db.prepare('SELECT id FROM users LIMIT 1').get() as any;
  const userId = (req.query.userId as string) || (req as any).user?.userId || defaultUser?.id;
  const missions = MissionsService.getAll(userId);
  res.json({ success: true, count: missions.length, data: missions });
});

// POST /api/v1/missions - Trigger or schedule a mission directly
missionsController.post('/', (req: Request, res: Response) => {
  try {
    const db = DatabaseService.getDb();
    const defaultUser = db.prepare('SELECT id FROM users LIMIT 1').get() as any;
    const userId = req.body.userId || (req as any).user?.userId || defaultUser?.id;
    const { alarmId, taskId, disciplineMode, scheduledAt, idempotencyKey } = req.body;
    if (!taskId) {
      res.status(400).json({ success: false, error: 'taskId is required' });
      return;
    }

    const mission = MissionsService.triggerMission({
      userId,
      alarmId,
      taskId,
      disciplineMode,
      scheduledAt,
      idempotencyKey
    });

    res.status(201).json({ success: true, data: mission });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/missions/current
missionsController.get('/current', authGuard, (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user!.userId;
  const active = MissionsService.getActive(userId);
  res.json({ success: true, mission: active });
});

// GET /api/v1/missions/today
missionsController.get('/today', authGuard, (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user!.userId;
  const missions = MissionsService.getToday(userId);
  res.json({ success: true, count: missions.length, data: missions });
});

// GET /api/v1/missions/active
missionsController.get('/active', authGuard, (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user!.userId;
  const active = MissionsService.getActive(userId);
  res.json({ success: true, data: active });
});

// POST /api/v1/missions/trigger
missionsController.post('/trigger', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.userId;
    const { alarmId, taskId, disciplineMode, scheduledAt, idempotencyKey } = req.body;
    if (!taskId) {
      res.status(400).json({ success: false, error: 'taskId is required' });
      return;
    }

    const mission = MissionsService.triggerMission({
      userId,
      alarmId,
      taskId,
      disciplineMode,
      scheduledAt,
      idempotencyKey
    });

    res.status(201).json({ success: true, data: mission });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/missions/:id/start
missionsController.post('/:id/start', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.userId;
    const existing = MissionsService.getById(String(req.params.id));
    if (!existing) {
      res.status(404).json({ success: false, error: 'Mission not found' });
      return;
    }
    if (existing.userId && existing.userId !== userId) {
      res.status(403).json({ success: false, error: 'FORBIDDEN_IDOR_VIOLATION: Cannot start mission belonging to another user' });
      return;
    }

    const mission = MissionsService.startMission(String(req.params.id));
    res.json({ success: true, data: mission });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/missions/:id/submit
missionsController.post('/:id/submit', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.userId;
    const { proofId, attemptId } = req.body;
    if (proofId) {
      const result = ProofsService.submitProofToMission({
        missionId: String(req.params.id),
        proofId,
        attemptId,
        userId
      });
      res.json({ success: true, data: result });
    } else {
      res.json({ success: true, data: { missionId: String(req.params.id), status: 'VERIFYING' } });
    }
  } catch (e: any) {
    const statusCode = e.message?.includes('FORBIDDEN_IDOR_VIOLATION') ? 403 : 400;
    res.status(statusCode).json({ success: false, error: e.message });
  }
});

// POST /api/v1/missions/:id/retry
missionsController.post('/:id/retry', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.userId;
    const existing = MissionsService.getById(String(req.params.id));
    if (!existing) {
      res.status(404).json({ success: false, error: 'Mission not found' });
      return;
    }
    if (existing.userId && existing.userId !== userId) {
      res.status(403).json({ success: false, error: 'FORBIDDEN_IDOR_VIOLATION: Cannot retry mission belonging to another user' });
      return;
    }

    const mission = MissionsService.retryMission(String(req.params.id));
    res.json({ success: true, data: mission });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/missions/:id/complete
missionsController.post('/:id/complete', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.userId;
    const existing = MissionsService.getById(String(req.params.id));
    if (!existing) {
      res.status(404).json({ success: false, error: 'Mission not found' });
      return;
    }
    if (existing.userId && existing.userId !== userId) {
      res.status(403).json({ success: false, error: 'FORBIDDEN_IDOR_VIOLATION: Cannot complete mission belonging to another user' });
      return;
    }

    const mission = MissionsService.completeMission(String(req.params.id));
    res.json({ success: true, data: mission });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/missions/:id/attempts
missionsController.get('/:id/attempts', authGuard, (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user!.userId;
  const existing = MissionsService.getById(String(req.params.id));
  if (!existing) {
    res.status(404).json({ success: false, error: 'Mission not found' });
    return;
  }
  if (existing.userId && existing.userId !== userId) {
    res.status(403).json({ success: false, error: 'FORBIDDEN_IDOR_VIOLATION: Cannot access attempts for mission belonging to another user' });
    return;
  }

  const attempts = MissionsService.getAttempts(String(req.params.id));
  res.json({ success: true, count: attempts.length, data: attempts });
});

// GET /api/v1/missions/:id
missionsController.get('/:id', authGuard, (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user!.userId;
  const mission = MissionsService.getById(String(req.params.id));
  if (!mission) {
    res.status(404).json({ success: false, error: 'Mission not found' });
    return;
  }
  if (mission.userId && mission.userId !== userId) {
    res.status(403).json({ success: false, error: 'FORBIDDEN_IDOR_VIOLATION: Cannot access mission belonging to another user' });
    return;
  }
  res.json({ success: true, data: mission });
});
