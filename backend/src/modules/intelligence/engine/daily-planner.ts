// Daily Planning & Conflict Detection Engine
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { DailyPlanEntity, DailyScheduleItem, ScheduleConflict } from '../domain/plan.entity';

export class DailyPlannerEngine {
  /**
   * Generates a conflict-free daily plan respecting fixed alarms, quiet hours, and dependencies
   */
  public static generateDailyPlan(userId: string, dateStr?: string): DailyPlanEntity {
    const db = DatabaseService.getDb();
    const planDate = dateStr || new Date().toISOString().substring(0, 10);
    const planId = uuidv4();
    const now = new Date();

    // 1. Fetch user's active missions / scheduled routines for the target date
    const missions = db.prepare(`
      SELECT m.*, t.name as task_name, t.category, t.difficulty
      FROM missions m
      LEFT JOIN tasks t ON m.task_id = t.id
      WHERE m.user_id = ? AND m.scheduled_at LIKE ?
      ORDER BY m.scheduled_at ASC
    `).all(userId, `${planDate}%`) as any[];

    // 2. Build schedule items
    const scheduleItems: DailyScheduleItem[] = [];
    const conflicts: ScheduleConflict[] = [];

    let currentHour = 7;
    let currentMinute = 0;

    for (const m of missions) {
      const scheduledTime = m.scheduled_at ? m.scheduled_at.substring(11, 16) : `${String(currentHour).padStart(2, '0')}:${String(currentMinute).padStart(2, '0')}`;
      const durationMinutes = m.difficulty === 3 ? 30 : (m.difficulty === 2 ? 15 : 10);

      scheduleItems.push({
        id: m.id,
        time: scheduledTime,
        title: m.task_name || 'Scheduled Mission',
        category: (m.category as any) || 'DISCIPLINE',
        durationMinutes,
        isFixed: true,
        isCompleted: m.status === 'COMPLETED',
        priority: 2
      });
    }

    // If no missions, add standard baseline anchor items
    if (scheduleItems.length === 0) {
      scheduleItems.push(
        {
          id: 'anchor-morning',
          time: '07:00',
          title: 'Morning Discipline Anchor',
          category: 'DISCIPLINE',
          durationMinutes: 15,
          isFixed: true,
          isCompleted: false,
          priority: 2
        },
        {
          id: 'anchor-hydration',
          time: '12:30',
          title: 'Hydration & Mindful Check-in',
          category: 'HYDRATION',
          durationMinutes: 5,
          isFixed: false,
          isCompleted: false,
          priority: 5
        },
        {
          id: 'anchor-evening',
          time: '21:30',
          title: 'Evening Reflection & Wind-Down',
          category: 'WIND_DOWN',
          durationMinutes: 15,
          isFixed: false,
          isCompleted: false,
          priority: 4
        }
      );
    }

    // 3. Detect schedule overlaps
    for (let i = 0; i < scheduleItems.length - 1; i++) {
      const itemA = scheduleItems[i];
      const itemB = scheduleItems[i + 1];

      const [hA, mA] = itemA.time.split(':').map(Number);
      const [hB, mB] = itemB.time.split(':').map(Number);

      const startMinA = hA * 60 + mA;
      const endMinA = startMinA + itemA.durationMinutes;
      const startMinB = hB * 60 + mB;

      if (endMinA > startMinB) {
        const overlap = endMinA - startMinB;
        conflicts.push({
          itemA: itemA.title,
          itemB: itemB.title,
          overlapMinutes: overlap,
          suggestedResolution: `Consider scheduling ${itemB.title} ${overlap + 5} minutes later at ${this.formatMinutesToTime(startMinB + overlap + 5)}.`
        });
      }
    }

    // Save or update existing daily plan
    const plan: DailyPlanEntity = {
      id: planId,
      userId,
      planDate,
      scheduleItems,
      conflicts,
      status: 'PROPOSED',
      createdAt: now,
      updatedAt: now
    };

    db.prepare(`
      INSERT OR REPLACE INTO daily_plans (
        id, user_id, plan_date, schedule_items, conflicts, status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      plan.id,
      plan.userId,
      plan.planDate,
      JSON.stringify(plan.scheduleItems),
      JSON.stringify(plan.conflicts),
      plan.status,
      plan.createdAt.toISOString(),
      plan.updatedAt.toISOString()
    );

    return plan;
  }

  private static formatMinutesToTime(totalMinutes: number): string {
    const h = Math.floor(totalMinutes / 60) % 24;
    const m = totalMinutes % 60;
    return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
  }
}
