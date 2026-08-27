// Multi-Stage Routine Stacks Service & Controller
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';

export class RoutinesService {
  public static getAll(userId: string) {
    const db = DatabaseService.getDb();
    const routineRows = db.prepare('SELECT * FROM routines WHERE user_id = ? ORDER BY trigger_time ASC').all(userId) as any[];

    return routineRows.map((r) => {
      const taskRows = db.prepare(`
        SELECT rt.step_order, t.id as task_id, t.title, t.category, t.proof_type, t.base_xp, t.icon_name
        FROM routine_tasks rt
        JOIN tasks t ON rt.task_id = t.id
        WHERE rt.routine_id = ?
        ORDER BY rt.step_order ASC
      `).all(r.id) as any[];

      return {
        id: r.id,
        userId: r.user_id,
        title: r.title,
        description: r.description,
        triggerTime: r.trigger_time,
        repeatDays: JSON.parse(r.repeat_days || '[]'),
        isEnabled: Boolean(r.is_enabled),
        totalSteps: taskRows.length,
        tasks: taskRows.map((t) => ({
          stepOrder: t.step_order,
          taskId: t.task_id,
          title: t.title,
          category: t.category,
          proofType: t.proof_type,
          baseXp: t.base_xp,
          iconName: t.icon_name
        })),
        createdAt: r.created_at
      };
    });
  }

  public static create(params: {
    userId: string;
    title: string;
    description: string;
    triggerTime: string;
    repeatDays?: number[];
    taskIds: string[];
  }) {
    const db = DatabaseService.getDb();
    const routineId = uuidv4();
    const now = new Date().toISOString();
    const repeatDays = JSON.stringify(params.repeatDays ?? [1, 2, 3, 4, 5]);

    db.prepare(`
      INSERT INTO routines (id, user_id, title, description, trigger_time, repeat_days, is_enabled, created_at)
      VALUES (?, ?, ?, ?, ?, ?, 1, ?)
    `).run(
      routineId,
      params.userId,
      params.title.trim(),
      params.description.trim(),
      params.triggerTime,
      repeatDays,
      now
    );

    // Link Tasks in Step Sequence
    const insertTaskLink = db.prepare(`
      INSERT INTO routine_tasks (id, routine_id, task_id, step_order)
      VALUES (?, ?, ?, ?)
    `);

    params.taskIds.forEach((taskId, index) => {
      insertTaskLink.run(uuidv4(), routineId, taskId, index + 1);
    });

    const created = this.getAll(params.userId).find((r) => r.id === routineId);
    return created;
  }

  public static delete(id: string, userId: string) {
    const db = DatabaseService.getDb();
    db.prepare('DELETE FROM routines WHERE id = ? AND user_id = ?').run(id, userId);
    return true;
  }
}

export const routinesController = Router();

// GET /api/v1/routines
routinesController.get('/', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const routines = RoutinesService.getAll(userId);
  res.json({ success: true, count: routines.length, data: routines });
});

// POST /api/v1/routines
routinesController.post('/', (req: Request, res: Response) => {
  try {
    const { userId, title, description, triggerTime, repeatDays, taskIds } = req.body;
    if (!title || !triggerTime || !taskIds || !Array.isArray(taskIds) || taskIds.length === 0) {
      res.status(400).json({ success: false, error: 'title, triggerTime, and taskIds array are required' });
      return;
    }

    const routine = RoutinesService.create({
      userId: userId || 'default-user',
      title,
      description: description || '',
      triggerTime,
      repeatDays,
      taskIds
    });

    res.status(201).json({ success: true, data: routine });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// DELETE /api/v1/routines/:id
routinesController.delete('/:id', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const success = RoutinesService.delete(String(req.params.id), userId);
  res.json({ success });
});
