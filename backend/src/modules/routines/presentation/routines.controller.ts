// Routine Planning, Scheduling & Planner REST Controller
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { RoutineEngine } from '../engine/routine-engine';
import { SchedulingEngine } from '../engine/scheduling-engine';
import { ConflictEngine, ScheduledTaskSlot } from '../engine/conflict-engine';
import { DependencyEngine } from '../engine/dependency-engine';
import { AdaptationEngine } from '../engine/adaptation-engine';

export const routinesController = Router();

// POST /api/v1/routines - Create Routine
routinesController.post('/', (req: Request, res: Response) => {
  try {
    const userId = req.body?.userId || (req.query?.userId as string) || 'default-user';
    const routine = RoutineEngine.createRoutine({
      userId,
      name: req.body?.name || 'New Routine',
      description: req.body?.description,
      type: req.body?.type || 'MORNING',
      minimumRequiredTasks: req.body?.minimumRequiredTasks || 1,
      tasks: req.body?.tasks || []
    });

    if (req.body?.schedule) {
      const db = DatabaseService.getDb();
      const sched = req.body.schedule;
      db.prepare(`
        INSERT INTO schedule_rules (
          id, user_id, routine_id, schedule_type, time_of_day, schedule_window_start, schedule_window_end,
          days_of_week, timezone, enabled, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
      `).run(
        uuidv4(),
        userId,
        routine.id,
        sched.scheduleType || 'WEEKDAYS',
        sched.timeOfDay || '07:00',
        sched.scheduleWindowStart || '06:45',
        sched.scheduleWindowEnd || '07:30',
        sched.daysOfWeek ? JSON.stringify(sched.daysOfWeek) : null,
        sched.timezone || 'UTC',
        new Date().toISOString(),
        new Date().toISOString()
      );
    }

    res.status(201).json({ success: true, data: RoutineEngine.getRoutineById(routine.id, userId) });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/routines - List user routines
routinesController.get('/', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const db = DatabaseService.getDb();
  const rows = db.prepare("SELECT id FROM routines WHERE user_id = ? AND status != 'ARCHIVED' ORDER BY created_at DESC").all(userId) as any[];
  const routines = rows.map((r) => RoutineEngine.getRoutineById(r.id, userId));
  res.json({ success: true, count: routines.length, data: routines });
});

// GET /api/v1/routines/:id - Get routine by ID
routinesController.get('/:id', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const routineId = String(req.params.id);
  const routine = RoutineEngine.getRoutineById(routineId, userId);
  if (!routine) return res.status(404).json({ success: false, error: 'ROUTINE_NOT_FOUND' });
  res.json({ success: true, data: routine });
});

// PATCH /api/v1/routines/:id - Update routine and increment version
routinesController.patch('/:id', (req: Request, res: Response) => {
  try {
    const userId = req.body?.userId || (req.query?.userId as string) || 'default-user';
    const routineId = String(req.params.id);
    const updated = RoutineEngine.updateRoutine({
      routineId,
      userId,
      name: req.body?.name,
      description: req.body?.description,
      status: req.body?.status,
      pauseUntil: req.body?.pauseUntil,
      tasks: req.body?.tasks
    });
    res.json({ success: true, data: updated });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// DELETE /api/v1/routines/:id - Archive routine (Soft delete)
routinesController.delete('/:id', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const routineId = String(req.params.id);
  const db = DatabaseService.getDb();
  db.prepare("UPDATE routines SET status = 'ARCHIVED', updated_at = ? WHERE id = ? AND user_id = ?").run(
    new Date().toISOString(),
    routineId,
    userId
  );
  res.json({ success: true, message: 'Routine archived successfully' });
});

// POST /api/v1/routines/:id/pause
routinesController.post('/:id/pause', (req: Request, res: Response) => {
  const userId = req.body?.userId || 'default-user';
  const routineId = String(req.params.id);
  const pauseUntil = req.body?.pauseUntil; // e.g. "2026-09-01"
  const db = DatabaseService.getDb();
  db.prepare("UPDATE routines SET status = 'PAUSED', pause_until = ?, updated_at = ? WHERE id = ? AND user_id = ?").run(
    pauseUntil || null,
    new Date().toISOString(),
    routineId,
    userId
  );
  res.json({ success: true, message: `Routine paused until ${pauseUntil || 'indefinitely'}` });
});

// POST /api/v1/routines/:id/resume
routinesController.post('/:id/resume', (req: Request, res: Response) => {
  const userId = req.body?.userId || 'default-user';
  const routineId = String(req.params.id);
  const db = DatabaseService.getDb();
  db.prepare("UPDATE routines SET status = 'ACTIVE', pause_until = NULL, updated_at = ? WHERE id = ? AND user_id = ?").run(
    new Date().toISOString(),
    routineId,
    userId
  );
  res.json({ success: true, message: 'Routine resumed to ACTIVE state' });
});

// GET /api/v1/routines/:id/analytics
routinesController.get('/:id/analytics', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const routineId = String(req.params.id);
  const analytics = RoutineEngine.getRoutineAnalytics(routineId, userId);
  res.json({ success: true, data: analytics });
});

// POST /api/v1/routines/generate-missions
routinesController.post('/generate-missions', (req: Request, res: Response) => {
  const userId = req.body?.userId || 'default-user';
  const days = req.body?.horizonDays || 7;
  const now = new Date();
  const endDate = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);

  const result = SchedulingEngine.generateMissions({
    userId,
    startDate: now,
    endDate,
    timezone: req.body?.timezone || 'UTC'
  });

  res.json({ success: true, data: result });
});

// POST /api/v1/routines/rest-days - Declare a rest day
routinesController.post('/rest-days', (req: Request, res: Response) => {
  const userId = req.body?.userId || 'default-user';
  const date = req.body?.date || new Date().toISOString().substring(0, 10);
  const reason = req.body?.reason || 'Rest & Recovery';
  const db = DatabaseService.getDb();

  db.prepare(`
    INSERT OR REPLACE INTO rest_days (id, user_id, date, reason, created_at)
    VALUES (?, ?, ?, ?, ?)
  `).run(uuidv4(), userId, date, reason, new Date().toISOString());

  res.json({ success: true, message: `Rest day recorded for ${date}` });
});

// GET /api/v1/planner - Unified Tactical Planner API
export const plannerController = Router();
plannerController.get('/', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const dateStr = (req.query?.date as string) || new Date().toISOString().substring(0, 10);
  const userTz = (req.query?.timezone as string) || 'UTC';
  const db = DatabaseService.getDb();

  // 1. Fetch Rest Day Status
  const restDayRow = db.prepare('SELECT * FROM rest_days WHERE user_id = ? AND date = ?').get(userId, dateStr) as any;

  // 2. Fetch User Routines
  const routineRows = db.prepare("SELECT id FROM routines WHERE user_id = ? AND status != 'ARCHIVED'").all(userId) as any[];
  const routines = routineRows.map((r) => RoutineEngine.getRoutineById(r.id, userId));

  // 3. Fetch Scheduled Missions for this date
  const missionRows = db.prepare(`
    SELECT m.*, t.name as task_name, t.category as task_category, t.difficulty as task_difficulty, t.proof_type as task_proof_type, t.base_xp as task_base_xp
    FROM missions m
    JOIN tasks t ON m.task_id = t.id
    WHERE m.user_id = ? AND m.scheduled_at LIKE ?
    ORDER BY m.scheduled_at ASC
  `).all(userId, `${dateStr}%`) as any[];

  // 4. Evaluate Conflicts
  const slots: ScheduledTaskSlot[] = missionRows.map((m) => {
    const start = new Date(m.scheduled_at);
    return {
      id: m.id,
      name: m.task_name,
      startTime: start,
      endTime: new Date(start.getTime() + 20 * 60 * 1000), // 20 min estimate
      routineId: m.routine_id,
      isMandatory: true
    };
  });
  const conflicts = ConflictEngine.detectConflicts(slots);

  res.json({
    success: true,
    data: {
      date: dateStr,
      timezone: userTz,
      isRestDay: Boolean(restDayRow),
      restDayReason: restDayRow?.reason,
      routines,
      missions: missionRows.map((m) => ({
        id: m.id,
        taskId: m.task_id,
        taskName: m.task_name,
        category: m.task_category,
        difficulty: m.task_difficulty,
        proofType: m.task_proof_type,
        baseXp: m.task_base_xp,
        scheduledAt: m.scheduled_at,
        status: m.status,
        source: m.source
      })),
      conflicts
    }
  });
});
