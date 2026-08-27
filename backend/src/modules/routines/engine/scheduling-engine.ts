// Rolling Horizon Mission Generation & Scheduling Engine
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { RecurrenceEngine } from './recurrence-engine';
import { ScheduleRuleEntity } from '../domain/schedule-rule.entity';

export interface GeneratedMissionInstance {
  id: string;
  userId: string;
  taskId: string;
  routineId?: string;
  scheduledAt: string;
  status: string;
  source: string;
  idempotencyKey: string;
}

export class SchedulingEngine {
  /**
   * Generates mission instances for a given date range (rolling horizon 7-14 days)
   */
  public static generateMissions(params: {
    userId: string;
    startDate: Date;
    endDate: Date;
    timezone?: string;
  }): { generatedCount: number; skippedCount: number; missions: GeneratedMissionInstance[] } {
    const db = DatabaseService.getDb();
    const userTz = params.timezone || 'UTC';

    // 1. Fetch Active Schedule Rules for User
    const rules = db.prepare(`
      SELECT * FROM schedule_rules 
      WHERE user_id = ? AND enabled = 1
    `).all(params.userId) as any[];

    // 2. Fetch User Rest Days
    const restDays = db.prepare('SELECT date FROM rest_days WHERE user_id = ?').all(params.userId) as any[];
    const restDaySet = new Set(restDays.map((r) => r.date));

    // 3. Fetch User Routines (and check paused status)
    const routines = db.prepare('SELECT * FROM routines WHERE user_id = ?').all(params.userId) as any[];
    const routineMap = new Map(routines.map((r) => [r.id, r]));

    const generatedMissions: GeneratedMissionInstance[] = [];
    let skippedCount = 0;

    let current = new Date(params.startDate);
    while (current <= params.endDate) {
      const dateStr = new Intl.DateTimeFormat('en-CA', {
        timeZone: userTz,
        year: 'numeric',
        month: '2-digit',
        day: '2-digit'
      }).format(current);

      // Check Rest Day
      if (restDaySet.has(dateStr)) {
        skippedCount++;
        current = new Date(current.getTime() + 24 * 60 * 60 * 1000);
        continue;
      }

      for (const rule of rules) {
        const scheduleRuleEntity: ScheduleRuleEntity = {
          id: rule.id,
          userId: rule.user_id,
          routineId: rule.routine_id,
          taskTemplateId: rule.task_template_id,
          scheduleType: rule.schedule_type,
          timeOfDay: rule.time_of_day,
          scheduleWindowStart: rule.schedule_window_start,
          scheduleWindowEnd: rule.schedule_window_end,
          daysOfWeek: rule.days_of_week ? JSON.parse(rule.days_of_week) : undefined,
          startDate: rule.start_date,
          endDate: rule.end_date,
          timezone: rule.timezone || userTz,
          enabled: Boolean(rule.enabled),
          createdAt: new Date(rule.created_at),
          updatedAt: new Date(rule.updated_at)
        };

        if (!RecurrenceEngine.occursOn(scheduleRuleEntity, current)) {
          continue;
        }

        // Check if attached routine is paused
        if (rule.routine_id) {
          const routine = routineMap.get(rule.routine_id);
          if (routine && routine.status === 'PAUSED') {
            if (!routine.pause_until || dateStr <= routine.pause_until.substring(0, 10)) {
              skippedCount++;
              continue;
            }
          }
          if (routine && routine.status === 'ARCHIVED') {
            continue;
          }
        }

        // Resolve Routine Tasks or Direct Task
        let tasksToSchedule: { taskTemplateId: string; offsetMinutes: number }[] = [];
        if (rule.routine_id) {
          const rTasks = db.prepare(`
            SELECT task_template_id, offset_minutes 
            FROM routine_tasks 
            WHERE routine_id = ? 
            ORDER BY sequence ASC
          `).all(rule.routine_id) as any[];
          tasksToSchedule = rTasks.map((rt) => ({
            taskTemplateId: rt.task_template_id,
            offsetMinutes: rt.offset_minutes || 0
          }));
        } else if (rule.task_template_id) {
          tasksToSchedule = [{ taskTemplateId: rule.task_template_id, offsetMinutes: 0 }];
        }

        const baseTimeStr = rule.time_of_day || '07:00';
        const [hh, mm] = baseTimeStr.split(':').map((n: string) => parseInt(n, 10));

        for (const t of tasksToSchedule) {
          // Compute scheduledAt with offset
          const scheduledDate = new Date(`${dateStr}T${String(hh).padStart(2, '0')}:${String(mm).padStart(2, '0')}:00.000Z`);
          const adjustedTime = new Date(scheduledDate.getTime() + t.offsetMinutes * 60 * 1000);
          const scheduledAtIso = adjustedTime.toISOString();

          const idempotencyKey = `${rule.id}:${dateStr}:${t.taskTemplateId}`;

          // Check if mission already exists for this occurrence
          const existing = db.prepare('SELECT id FROM missions WHERE idempotency_key = ?').get(idempotencyKey) as any;
          if (existing) {
            skippedCount++;
            continue;
          }

          const missionId = uuidv4();
          const nowIso = new Date().toISOString();

          // Resolve task ID from tasks table or task_templates
          const taskRow = db.prepare('SELECT id FROM tasks WHERE id = ?').get(t.taskTemplateId) as any;
          let resolvedTaskId = taskRow?.id;
          if (!resolvedTaskId) {
            const tpl = db.prepare('SELECT * FROM task_templates WHERE id = ?').get(t.taskTemplateId) as any;
            if (tpl) {
              resolvedTaskId = tpl.id;
              db.prepare(`
                INSERT OR IGNORE INTO tasks (
                  id, user_id, template_id, slug, title, name, description, instructions, category, difficulty, proof_type, verification_type, base_xp, validation_rules, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, 'Execute routine step', ?, ?, ?, 'BASIC', ?, '{}', ?, ?)
              `).run(
                tpl.id,
                params.userId,
                tpl.id,
                `slug-${tpl.id}-${uuidv4().substring(0, 6)}`,
                tpl.name || 'Task',
                tpl.name || 'Task',
                tpl.description || 'Task description',
                tpl.category || 'GENERAL',
                tpl.difficulty || 1,
                tpl.proof_type || 'PHOTO',
                tpl.base_xp || 20,
                nowIso,
                nowIso
              );
            } else {
              resolvedTaskId = t.taskTemplateId;
              db.prepare(`
                INSERT OR IGNORE INTO tasks (
                  id, user_id, slug, title, name, description, instructions, category, proof_type, validation_rules, created_at, updated_at
                ) VALUES (?, ?, ?, 'Routine Task', 'Routine Task', 'Routine task item', 'Execute task', 'GENERAL', 'PHOTO', '{}', ?, ?)
              `).run(
                resolvedTaskId,
                params.userId,
                `slug-${resolvedTaskId}-${uuidv4().substring(0, 6)}`,
                nowIso,
                nowIso
              );
            }
          }

          db.prepare(`
            INSERT INTO missions (
              id, user_id, task_id, scheduled_at, status, source, idempotency_key, created_at, updated_at
            ) VALUES (?, ?, ?, ?, 'SCHEDULED', 'ROUTINE', ?, ?, ?)
          `).run(
            missionId,
            params.userId,
            resolvedTaskId,
            scheduledAtIso,
            idempotencyKey,
            nowIso,
            nowIso
          );

          generatedMissions.push({
            id: missionId,
            userId: params.userId,
            taskId: resolvedTaskId,
            routineId: rule.routine_id,
            scheduledAt: scheduledAtIso,
            status: 'SCHEDULED',
            source: 'ROUTINE',
            idempotencyKey
          });
        }
      }

      current = new Date(current.getTime() + 24 * 60 * 60 * 1000);
    }

    return {
      generatedCount: generatedMissions.length,
      skippedCount,
      missions: generatedMissions
    };
  }
}
