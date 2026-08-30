// Alarms Service & Controller with Recurrence Engine & Full CRUD
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { AlarmReliabilityService } from './services/alarm-reliability.service';
import { AlarmOccurrenceRepository } from '../../repositories/alarm-occurrence.repository';

export class AlarmsService {
  public static getAll(userId: string) {
    const db = DatabaseService.getDb();
    const rows = db.prepare(`
      SELECT 
        a.id, a.user_id, a.task_id, a.time_of_day, a.timezone, a.repeat_days, 
        a.discipline_mode, a.retry_interval_minutes, a.is_enabled, a.created_at, a.updated_at,
        t.title as task_title, t.category as task_category, t.proof_type as task_proof_type,
        t.base_xp as task_base_xp, t.icon_name as task_icon_name
      FROM alarms a
      JOIN tasks t ON a.task_id = t.id
      WHERE a.user_id = ?
      ORDER BY a.time_of_day ASC
    `).all(userId) as any[];

    return rows.map(this.mapToAlarm);
  }

  public static getById(id: string) {
    const db = DatabaseService.getDb();
    const row = db.prepare(`
      SELECT 
        a.id, a.user_id, a.task_id, a.time_of_day, a.timezone, a.repeat_days, 
        a.discipline_mode, a.retry_interval_minutes, a.is_enabled, a.created_at, a.updated_at,
        t.title as task_title, t.category as task_category, t.proof_type as task_proof_type,
        t.base_xp as task_base_xp, t.icon_name as task_icon_name
      FROM alarms a
      JOIN tasks t ON a.task_id = t.id
      WHERE a.id = ?
    `).get(id) as any;

    if (!row) return null;
    return this.mapToAlarm(row);
  }

  public static create(params: {
    userId: string;
    taskId: string;
    timeOfDay: string; // "07:00" or "07:00:00"
    timezone?: string;
    repeatDays?: number[]; // [1, 2, 3, 4, 5]
    disciplineMode?: string;
    retryIntervalMinutes?: number;
  }) {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();
    const formattedTime = params.timeOfDay.length === 5 ? `${params.timeOfDay}:00` : params.timeOfDay;
    const repeatDays = JSON.stringify(params.repeatDays ?? [1, 2, 3, 4, 5]);

    db.prepare(`
      INSERT INTO alarms (id, user_id, task_id, time_of_day, timezone, repeat_days, discipline_mode, retry_interval_minutes, is_enabled, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
    `).run(
      id,
      params.userId,
      params.taskId,
      formattedTime,
      params.timezone || 'UTC',
      repeatDays,
      params.disciplineMode || 'DISCIPLINE',
      params.retryIntervalMinutes || 5,
      now,
      now
    );

    return this.getById(id);
  }

  public static update(id: string, updates: {
    timeOfDay?: string;
    repeatDays?: number[];
    disciplineMode?: string;
    retryIntervalMinutes?: number;
    taskId?: string;
  }) {
    const db = DatabaseService.getDb();
    const existing = this.getById(id);
    if (!existing) return null;

    const formattedTime = updates.timeOfDay
      ? (updates.timeOfDay.length === 5 ? `${updates.timeOfDay}:00` : updates.timeOfDay)
      : existing.timeOfDay;

    const repeatDays = updates.repeatDays !== undefined
      ? JSON.stringify(updates.repeatDays)
      : JSON.stringify(existing.repeatDays);

    const now = new Date().toISOString();

    db.prepare(`
      UPDATE alarms 
      SET time_of_day = ?, repeat_days = ?, discipline_mode = ?, retry_interval_minutes = ?, task_id = ?, updated_at = ?
      WHERE id = ?
    `).run(
      formattedTime,
      repeatDays,
      updates.disciplineMode || existing.disciplineMode,
      updates.retryIntervalMinutes || existing.retryIntervalMinutes,
      updates.taskId || existing.taskId,
      now,
      id
    );

    return this.getById(id);
  }

  public static toggle(id: string) {
    const db = DatabaseService.getDb();
    const existing = this.getById(id);
    if (!existing) return null;

    const newEnabled = existing.isEnabled ? 0 : 1;
    const now = new Date().toISOString();

    db.prepare('UPDATE alarms SET is_enabled = ?, updated_at = ? WHERE id = ?').run(newEnabled, now, id);
    return this.getById(id);
  }

  public static delete(id: string) {
    const db = DatabaseService.getDb();
    db.prepare('DELETE FROM alarms WHERE id = ?').run(id);
    return true;
  }

  public static getNextAlarm(userId: string) {
    const alarms = this.getAll(userId).filter((a) => a.isEnabled);
    if (alarms.length === 0) return null;

    const now = new Date();
    let earliestTrigger: { alarm: any; nextDate: Date } | null = null;

    for (const alarm of alarms) {
      const parts = alarm.timeOfDay.split(':');
      const targetHour = parseInt(parts[0], 10);
      const targetMinute = parseInt(parts[1], 10);

      const repeatDays = alarm.repeatDays as number[];
      let candidateDate: Date | null = null;

      // 1. One-Shot
      if (repeatDays.length === 0) {
        const d = new Date(now);
        d.setHours(targetHour, targetMinute, 0, 0);
        if (d.getTime() > now.getTime()) {
          candidateDate = d;
        } else {
          d.setDate(d.getDate() + 1);
          candidateDate = d;
        }
      } else {
        // 2. Repeating
        // Check today
        const currentIsoWeekday = now.getDay() === 0 ? 7 : now.getDay();
        if (repeatDays.includes(currentIsoWeekday)) {
          const d = new Date(now);
          d.setHours(targetHour, targetMinute, 0, 0);
          if (d.getTime() > now.getTime()) {
            candidateDate = d;
          }
        }

        // Check next 7 days
        if (!candidateDate) {
          for (let offset = 1; offset <= 7; offset++) {
            const d = new Date(now);
            d.setDate(d.getDate() + offset);
            d.setHours(targetHour, targetMinute, 0, 0);
            const isoDay = d.getDay() === 0 ? 7 : d.getDay();
            if (repeatDays.includes(isoDay)) {
              candidateDate = d;
              break;
            }
          }
        }
      }

      if (candidateDate) {
        if (!earliestTrigger || candidateDate.getTime() < earliestTrigger.nextDate.getTime()) {
          earliestTrigger = { alarm, nextDate: candidateDate };
        }
      }
    }

    if (!earliestTrigger) return null;

    return {
      alarm: earliestTrigger.alarm,
      nextOccurrence: earliestTrigger.nextDate.toISOString()
    };
  }

  private static mapToAlarm(row: any) {
    return {
      id: row.id,
      userId: row.user_id,
      taskId: row.task_id,
      taskTitle: row.task_title,
      taskCategory: row.task_category,
      taskProofType: row.task_proof_type,
      taskBaseXp: row.task_base_xp,
      taskIconName: row.task_icon_name,
      timeOfDay: row.time_of_day,
      timezone: row.timezone,
      repeatDays: JSON.parse(row.repeat_days || '[]'),
      disciplineMode: row.discipline_mode,
      retryIntervalMinutes: row.retry_interval_minutes,
      isEnabled: Boolean(row.is_enabled),
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };
  }
}

export const alarmsController = Router();

// GET /api/v1/alarms/next - Next upcoming alarm
alarmsController.get('/next', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const next = AlarmsService.getNextAlarm(userId);
  res.json({ success: true, data: next });
});

// GET /api/v1/alarms - List user alarms
alarmsController.get('/', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const alarms = AlarmsService.getAll(userId);
  res.json({ success: true, count: alarms.length, data: alarms });
});

// GET /api/v1/alarms/:id - Single alarm
alarmsController.get('/:id', (req: Request, res: Response) => {
  const alarm = AlarmsService.getById(String(req.params.id));
  if (!alarm) {
    res.status(404).json({ success: false, error: 'Alarm not found' });
    return;
  }
  res.json({ success: true, data: alarm });
});

// POST /api/v1/alarms - Create alarm commitment
alarmsController.post('/', (req: Request, res: Response) => {
  try {
    const { userId, taskId, timeOfDay, timezone, repeatDays, disciplineMode, retryIntervalMinutes } = req.body;
    if (!taskId || !timeOfDay) {
      res.status(400).json({ success: false, error: 'taskId and timeOfDay are required.' });
      return;
    }

    const alarm = AlarmsService.create({
      userId: userId || 'default-user',
      taskId,
      timeOfDay,
      timezone,
      repeatDays,
      disciplineMode,
      retryIntervalMinutes
    });

    res.status(201).json({ success: true, data: alarm });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// PATCH /api/v1/alarms/:id/toggle - Toggle enabled state
alarmsController.patch('/:id/toggle', (req: Request, res: Response) => {
  const alarm = AlarmsService.toggle(String(req.params.id));
  if (!alarm) {
    res.status(404).json({ success: false, error: 'Alarm not found' });
    return;
  }
  res.json({ success: true, data: alarm });
});

// PATCH /api/v1/alarms/:id - Update schedule
alarmsController.patch('/:id', (req: Request, res: Response) => {
  const updated = AlarmsService.update(String(req.params.id), req.body);
  if (!updated) {
    res.status(404).json({ success: false, error: 'Alarm not found' });
    return;
  }
  res.json({ success: true, data: updated });
});

// POST /api/v1/alarms/diagnose - Check device health & OEM mitigations
alarmsController.post('/diagnose', (req: Request, res: Response) => {
  try {
    const health = AlarmReliabilityService.diagnoseDevice(req.body);
    res.json({ success: true, data: health });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/alarms/test-alarm/start - Start "Test My Alarm" session
alarmsController.post('/test-alarm/start', (req: Request, res: Response) => {
  try {
    const delaySeconds = req.body.delaySeconds || 60;
    const session = AlarmReliabilityService.startTestAlarm(delaySeconds);
    res.status(201).json({ success: true, data: session });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/alarms/test-alarm/:testId/confirm - User confirms delivery
alarmsController.post('/test-alarm/:testId/confirm', (req: Request, res: Response) => {
  try {
    const result = AlarmReliabilityService.confirmTestAlarm(String(req.params.testId));
    res.json({ success: true, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/alarms/occurrences/:occurrenceId/trigger - Acknowledge native trigger
alarmsController.post('/occurrences/:occurrenceId/trigger', (req: Request, res: Response) => {
  try {
    const occurrenceId = String(req.params.occurrenceId);
    let occurrence = AlarmOccurrenceRepository.findById(occurrenceId);
    if (!occurrence) {
      // Auto-create occurrence if first time reported by native layer
      const { alarmId, missionId, userId, scheduledAt, platform } = req.body;
      if (alarmId && missionId && userId) {
        occurrence = AlarmOccurrenceRepository.create({
          occurrenceId,
          alarmId,
          missionId,
          userId,
          scheduledAt: scheduledAt || new Date().toISOString(),
          platform: platform || 'android'
        });
      }
    }

    if (!occurrence) {
      res.status(404).json({ success: false, error: 'Occurrence not found and required fields missing for creation' });
      return;
    }

    AlarmOccurrenceRepository.markTriggered(occurrenceId);
    res.json({ success: true, data: AlarmOccurrenceRepository.findById(occurrenceId) });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/alarms/occurrences/:occurrenceId/disarm - Complete mission and disarm occurrence
alarmsController.post('/occurrences/:occurrenceId/disarm', (req: Request, res: Response) => {
  try {
    const occurrenceId = String(req.params.occurrenceId);
    const occurrence = AlarmOccurrenceRepository.findById(occurrenceId);
    if (!occurrence) {
      res.status(404).json({ success: false, error: 'Occurrence not found' });
      return;
    }

    const { completedAt } = req.body;
    AlarmOccurrenceRepository.markDisarmed(occurrenceId, completedAt);
    res.json({ success: true, data: AlarmOccurrenceRepository.findById(occurrenceId) });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/alarms/:id/occurrences - Observability audit log
alarmsController.get('/:id/occurrences', (req: Request, res: Response) => {
  try {
    const occurrences = AlarmOccurrenceRepository.findByAlarmId(String(req.params.id));
    res.json({ success: true, data: occurrences });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// DELETE /api/v1/alarms/:id - Delete alarm commitment
alarmsController.delete('/:id', (req: Request, res: Response) => {
  AlarmsService.delete(String(req.params.id));
  res.json({ success: true });
});
