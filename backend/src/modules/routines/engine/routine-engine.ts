// Routine Engine & Versioning Lifecycle Manager
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { RoutineEntity, RoutineStatus, RoutineType } from '../domain/routine.entity';
import { RoutineTaskEntity } from '../domain/routine-task.entity';

export class RoutineEngine {
  /**
   * Creates a new routine with optional task items
   */
  public static createRoutine(params: {
    userId: string;
    name: string;
    description?: string;
    type: RoutineType;
    minimumRequiredTasks?: number;
    tasks?: { taskTemplateId: string; sequence: number; offsetMinutes?: number; required?: boolean }[];
  }): RoutineEntity {
    const db = DatabaseService.getDb();
    const routineId = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO routines (id, user_id, name, description, type, status, version, minimum_required_tasks, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, 'ACTIVE', 1, ?, ?, ?)
    `).run(
      routineId,
      params.userId,
      params.name,
      params.description || null,
      params.type,
      params.minimumRequiredTasks || 1,
      now,
      now
    );

    const routineTasks: RoutineTaskEntity[] = [];
    if (params.tasks && params.tasks.length > 0) {
      for (const t of params.tasks) {
        const taskId = uuidv4();
        db.prepare(`
          INSERT INTO routine_tasks (id, routine_id, task_template_id, sequence, offset_minutes, required, created_at)
          VALUES (?, ?, ?, ?, ?, ?, ?)
        `).run(taskId, routineId, t.taskTemplateId, t.sequence, t.offsetMinutes || 0, t.required !== false ? 1 : 0, now);

        routineTasks.push({
          id: taskId,
          routineId,
          taskTemplateId: t.taskTemplateId,
          sequence: t.sequence,
          offsetMinutes: t.offsetMinutes || 0,
          required: t.required !== false,
          createdAt: new Date()
        });
      }
    }

    // Save initial version 1 snapshot
    db.prepare(`
      INSERT INTO routine_versions (id, routine_id, version, configuration, created_at)
      VALUES (?, ?, 1, ?, ?)
    `).run(uuidv4(), routineId, JSON.stringify({ name: params.name, type: params.type, tasks: params.tasks || [] }), now);

    return {
      id: routineId,
      userId: params.userId,
      name: params.name,
      description: params.description,
      type: params.type,
      status: 'ACTIVE',
      version: 1,
      minimumRequiredTasks: params.minimumRequiredTasks || 1,
      tasks: routineTasks,
      createdAt: new Date(),
      updatedAt: new Date()
    };
  }

  /**
   * Updates an existing routine and creates a new immutable version snapshot
   */
  public static updateRoutine(params: {
    routineId: string;
    userId: string;
    name?: string;
    description?: string;
    status?: RoutineStatus;
    pauseUntil?: string;
    tasks?: { taskTemplateId: string; sequence: number; offsetMinutes?: number; required?: boolean }[];
  }): RoutineEntity {
    const db = DatabaseService.getDb();
    const existing = db.prepare('SELECT * FROM routines WHERE id = ? AND user_id = ?').get(params.routineId, params.userId) as any;
    if (!existing) throw new Error('ROUTINE_NOT_FOUND: Routine not found or unauthorized');

    const nextVersion = existing.version + 1;
    const now = new Date().toISOString();
    const updatedName = params.name !== undefined ? params.name : existing.name;
    const updatedDesc = params.description !== undefined ? params.description : existing.description;
    const updatedStatus = params.status !== undefined ? params.status : existing.status;
    const updatedPause = params.pauseUntil !== undefined ? params.pauseUntil : existing.pause_until;

    db.prepare(`
      UPDATE routines 
      SET name = ?, description = ?, status = ?, pause_until = ?, version = ?, updated_at = ?
      WHERE id = ?
    `).run(updatedName, updatedDesc, updatedStatus, updatedPause, nextVersion, now, params.routineId);

    // Update tasks if provided
    let routineTasks: RoutineTaskEntity[] = [];
    if (params.tasks) {
      db.prepare('DELETE FROM routine_tasks WHERE routine_id = ?').run(params.routineId);
      for (const t of params.tasks) {
        const taskId = uuidv4();
        db.prepare(`
          INSERT INTO routine_tasks (id, routine_id, task_template_id, sequence, offset_minutes, required, created_at)
          VALUES (?, ?, ?, ?, ?, ?, ?)
        `).run(taskId, params.routineId, t.taskTemplateId, t.sequence, t.offsetMinutes || 0, t.required !== false ? 1 : 0, now);

        routineTasks.push({
          id: taskId,
          routineId: params.routineId,
          taskTemplateId: t.taskTemplateId,
          sequence: t.sequence,
          offsetMinutes: t.offsetMinutes || 0,
          required: t.required !== false,
          createdAt: new Date()
        });
      }
    } else {
      const rows = db.prepare('SELECT * FROM routine_tasks WHERE routine_id = ? ORDER BY sequence ASC').all(params.routineId) as any[];
      routineTasks = rows.map((r) => ({
        id: r.id,
        routineId: r.routine_id,
        taskTemplateId: r.task_template_id,
        sequence: r.sequence,
        offsetMinutes: r.offset_minutes,
        required: Boolean(r.required),
        createdAt: new Date(r.created_at)
      }));
    }

    // Save new version snapshot
    db.prepare(`
      INSERT INTO routine_versions (id, routine_id, version, configuration, created_at)
      VALUES (?, ?, ?, ?, ?)
    `).run(uuidv4(), params.routineId, nextVersion, JSON.stringify({ name: updatedName, status: updatedStatus, tasks: routineTasks }), now);

    return {
      id: params.routineId,
      userId: params.userId,
      name: updatedName,
      description: updatedDesc,
      type: existing.type,
      status: updatedStatus,
      version: nextVersion,
      pauseUntil: updatedPause,
      minimumRequiredTasks: existing.minimum_required_tasks,
      tasks: routineTasks,
      createdAt: new Date(existing.created_at),
      updatedAt: new Date()
    };
  }

  /**
   * Retrieves full routine details by ID
   */
  public static getRoutineById(routineId: string, userId?: string): RoutineEntity | null {
    const db = DatabaseService.getDb();
    const query = userId
      ? db.prepare('SELECT * FROM routines WHERE id = ? AND user_id = ?').get(routineId, userId) as any
      : db.prepare('SELECT * FROM routines WHERE id = ?').get(routineId) as any;

    if (!query) return null;

    const taskRows = db.prepare('SELECT * FROM routine_tasks WHERE routine_id = ? ORDER BY sequence ASC').all(routineId) as any[];
    const scheduleRow = db.prepare('SELECT * FROM schedule_rules WHERE routine_id = ?').get(routineId) as any;

    return {
      id: query.id,
      userId: query.user_id,
      name: query.name,
      description: query.description,
      type: query.type,
      status: query.status,
      version: query.version,
      pauseUntil: query.pause_until,
      minimumRequiredTasks: query.minimum_required_tasks,
      tasks: taskRows.map((r) => ({
        id: r.id,
        routineId: r.routine_id,
        taskTemplateId: r.task_template_id,
        sequence: r.sequence,
        offsetMinutes: r.offset_minutes,
        required: Boolean(r.required),
        createdAt: new Date(r.created_at)
      })),
      schedule: scheduleRow
        ? {
            id: scheduleRow.id,
            userId: scheduleRow.user_id,
            routineId: scheduleRow.routine_id,
            taskTemplateId: scheduleRow.task_template_id,
            scheduleType: scheduleRow.schedule_type,
            timeOfDay: scheduleRow.time_of_day,
            scheduleWindowStart: scheduleRow.schedule_window_start,
            scheduleWindowEnd: scheduleRow.schedule_window_end,
            daysOfWeek: scheduleRow.days_of_week ? JSON.parse(scheduleRow.days_of_week) : undefined,
            startDate: scheduleRow.start_date,
            endDate: scheduleRow.end_date,
            timezone: scheduleRow.timezone,
            enabled: Boolean(scheduleRow.enabled),
            createdAt: new Date(scheduleRow.created_at),
            updatedAt: new Date(scheduleRow.updated_at)
          }
        : undefined,
      createdAt: new Date(query.created_at),
      updatedAt: new Date(query.updated_at)
    };
  }

  /**
   * Computes routine health and completion rate analytics
   */
  public static getRoutineAnalytics(routineId: string, userId: string) {
    const db = DatabaseService.getDb();
    const missionCountRow = db.prepare(`
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) as completed,
        AVG(resistance_seconds) as avg_resistance
      FROM missions 
      WHERE user_id = ? AND source = 'ROUTINE'
    `).get(userId) as any;

    const total = missionCountRow?.total || 0;
    const completed = missionCountRow?.completed || 0;
    const rate = total > 0 ? Math.round((completed / total) * 100) : 100;
    const health = rate >= 80 ? 'GOOD' : rate >= 50 ? 'MODERATE' : 'NEEDS_ADJUSTMENT';

    return {
      routineId,
      totalScheduled: total,
      totalCompleted: completed,
      completionRate: rate,
      averageDelaySeconds: Math.round(missionCountRow?.avg_resistance || 0),
      routineHealth: health
    };
  }
}
