// Authoritative Scheduling & Alarm Session Engine Controller
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { authGuard, AuthenticatedRequest } from '../../common/guards/auth.guard';
import { ScheduleCalculator } from './schedule-calculator';
import { RetryEngine } from './retry-engine';
import { v4 as uuidv4 } from 'uuid';

export class SchedulingService {
  // 1. Alarm Schedule CRUD
  public static createSchedule(userId: string, params: {
    taskId: string;
    startTime: string;
    repeatType?: 'ONCE' | 'DAILY' | 'WEEKLY' | 'CUSTOM';
    daysOfWeek?: string[];
    timezone?: string;
    retryIntervalMinutes?: number;
    sound?: string;
    vibration?: boolean;
  }) {
    const db = DatabaseService.getDb();
    const task = db.prepare('SELECT * FROM tasks WHERE id = ?').get(params.taskId) as any;
    if (!task) throw new Error('Task not found');

    const id = uuidv4();
    const now = new Date().toISOString();
    const repeatType = params.repeatType || 'DAILY';
    const daysOfWeek = JSON.stringify(params.daysOfWeek || ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY']);
    const timezone = params.timezone || 'UTC';
    const retryInterval = params.retryIntervalMinutes || 5;

    db.prepare(`
      INSERT INTO alarms (id, user_id, task_id, time_of_day, timezone, repeat_days, retry_interval_minutes, is_enabled, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
    `).run(
      id,
      userId,
      params.taskId,
      params.startTime,
      timezone,
      daysOfWeek,
      retryInterval,
      now,
      now
    );

    return this.getScheduleById(id, userId);
  }

  public static getScheduleById(id: string, userId?: string) {
    const db = DatabaseService.getDb();
    let query = 'SELECT * FROM alarms WHERE id = ?';
    const params: any[] = [id];

    if (userId) {
      query += ' AND user_id = ?';
      params.push(userId);
    }

    const row = db.prepare(query).get(...params) as any;
    if (!row) throw new Error('Alarm schedule not found or access unauthorized.');

    return this.mapSchedule(row);
  }

  public static getUserSchedules(userId: string) {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM alarms WHERE user_id = ? ORDER BY time_of_day ASC').all(userId) as any[];
    return rows.map((r) => this.mapSchedule(r));
  }

  public static setScheduleEnabled(id: string, userId: string, enabled: boolean) {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();

    db.prepare('UPDATE alarms SET is_enabled = ?, updated_at = ? WHERE id = ? AND user_id = ?').run(
      enabled ? 1 : 0,
      now,
      id,
      userId
    );

    return this.getScheduleById(id, userId);
  }

  public static deleteSchedule(id: string, userId: string): boolean {
    const db = DatabaseService.getDb();
    db.prepare('DELETE FROM alarms WHERE id = ? AND user_id = ?').run(id, userId);
    return true;
  }

  // 2. Mission Generation & Task Snapshotting
  public static generateMissionForSchedule(scheduleId: string, scheduledForDate?: string) {
    const db = DatabaseService.getDb();
    const schedule = db.prepare('SELECT * FROM alarms WHERE id = ?').get(scheduleId) as any;
    if (!schedule || !schedule.is_enabled) return null;

    const task = db.prepare('SELECT * FROM tasks WHERE id = ?').get(schedule.task_id) as any;
    if (!task || task.status === 'PAUSED' || task.status === 'ARCHIVED') return null;

    const now = new Date();
    const scheduledFor = scheduledForDate || now.toISOString();
    const idempotencyKey = `${scheduleId}_${scheduledFor.substring(0, 10)}`;

    // Idempotency: Prevent duplicate mission generation
    const existingMission = db.prepare('SELECT * FROM missions WHERE idempotency_key = ?').get(idempotencyKey) as any;
    if (existingMission) {
      return existingMission;
    }

    const missionId = uuidv4();
    const createdAt = now.toISOString();

    db.prepare(`
      INSERT INTO missions (id, user_id, alarm_id, task_id, scheduled_at, status, attempt_count, discipline_mode, idempotency_key, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, 'SCHEDULED', 1, ?, ?, ?, ?)
    `).run(
      missionId,
      schedule.user_id,
      schedule.id,
      task.id,
      scheduledFor,
      schedule.discipline_mode || 'DISCIPLINE',
      idempotencyKey,
      createdAt,
      createdAt
    );

    // Initial Attempt #1
    db.prepare(`
      INSERT INTO mission_attempts (id, mission_id, attempt_index, triggered_at, status, siren_volume_level)
      VALUES (?, ?, 1, ?, 'SCHEDULED', 70)
    `).run(uuidv4(), missionId, scheduledFor);

    return db.prepare('SELECT * FROM missions WHERE id = ?').get(missionId);
  }

  // 3. Client Synchronization Endpoint
  public static getSyncAlarms(userId: string) {
    const db = DatabaseService.getDb();
    const now = new Date();

    const activeMissions = db.prepare(`
      SELECT m.id as mission_id, m.task_id, m.scheduled_at, m.status, a.attempt_index, a.triggered_at, a.siren_volume_level
      FROM missions m
      LEFT JOIN mission_attempts a ON m.id = a.mission_id AND a.status = 'SCHEDULED'
      WHERE m.user_id = ? AND m.status IN ('SCHEDULED', 'ACTIVE', 'TRIGGERED', 'SUBMITTED', 'VERIFYING')
    `).all(userId) as any[];

    return {
      serverTime: now.toISOString(),
      activeAlarms: activeMissions.map((r) => ({
        missionId: r.mission_id,
        taskId: r.task_id,
        scheduledAt: r.triggered_at || r.scheduled_at,
        attemptNumber: r.attempt_index || 1,
        volumeLevel: r.siren_volume_level || 70,
        status: r.status
      }))
    };
  }

  private static mapSchedule(row: any) {
    let days: string[] = [];
    try {
      days = JSON.parse(row.repeat_days || '[]');
    } catch {
      days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY'];
    }

    const nextInfo = ScheduleCalculator.calculateNextOccurrence({
      startTime: row.time_of_day,
      repeatType: 'CUSTOM',
      daysOfWeek: days,
      timezone: row.timezone
    });

    return {
      id: row.id,
      userId: row.user_id,
      taskId: row.task_id,
      startTime: row.time_of_day,
      timeOfDay: row.time_of_day,
      timezone: row.timezone,
      repeatDays: days,
      retryIntervalMinutes: row.retry_interval_minutes || 5,
      isEnabled: Boolean(row.is_enabled),
      nextOccurrence: nextInfo.nextOccurrence,
      secondsUntil: nextInfo.secondsUntil,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };
  }
}

export const schedulingController = Router();

// GET /api/v1/alarm-schedules
schedulingController.get('/', authGuard, (req: AuthenticatedRequest, res: Response) => {
  const schedules = SchedulingService.getUserSchedules(req.user!.userId);
  res.json({ success: true, count: schedules.length, data: schedules });
});

// POST /api/v1/alarm-schedules
schedulingController.post('/', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const schedule = SchedulingService.createSchedule(req.user!.userId, req.body);
    res.status(201).json({ success: true, data: schedule });
  } catch (err: any) {
    res.status(400).json({ success: false, error: { message: err.message } });
  }
});

// GET /api/v1/alarm-schedules/:id
schedulingController.get('/:id', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const schedule = SchedulingService.getScheduleById(id, req.user!.userId);
    res.json({ success: true, data: schedule });
  } catch (err: any) {
    res.status(404).json({ success: false, error: { message: err.message } });
  }
});

// POST /api/v1/alarm-schedules/:id/enable
schedulingController.post('/:id/enable', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const schedule = SchedulingService.setScheduleEnabled(id, req.user!.userId, true);
    res.json({ success: true, data: schedule });
  } catch (err: any) {
    res.status(400).json({ success: false, error: { message: err.message } });
  }
});

// POST /api/v1/alarm-schedules/:id/disable
schedulingController.post('/:id/disable', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const schedule = SchedulingService.setScheduleEnabled(id, req.user!.userId, false);
    res.json({ success: true, data: schedule });
  } catch (err: any) {
    res.status(400).json({ success: false, error: { message: err.message } });
  }
});

// DELETE /api/v1/alarm-schedules/:id
schedulingController.delete('/:id', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    SchedulingService.deleteSchedule(id, req.user!.userId);
    res.json({ success: true, message: 'Alarm schedule deleted.' });
  } catch (err: any) {
    res.status(400).json({ success: false, error: { message: err.message } });
  }
});
