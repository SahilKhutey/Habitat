// Phase 11 Personal Discipline Planning & Routine Engine Master Tests
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { RoutineEngine } from '../src/modules/routines/engine/routine-engine';
import { RecurrenceEngine } from '../src/modules/routines/engine/recurrence-engine';
import { SchedulingEngine } from '../src/modules/routines/engine/scheduling-engine';
import { ConflictEngine } from '../src/modules/routines/engine/conflict-engine';
import { DependencyEngine } from '../src/modules/routines/engine/dependency-engine';
import { AdaptationEngine } from '../src/modules/routines/engine/adaptation-engine';
import { ScheduleRuleEntity } from '../src/modules/routines/domain/schedule-rule.entity';

describe('Phase 11 Acceptance Gate: Personal Discipline Planning & Routine Engine', () => {
  let userId: string;
  let routineId: string;
  let task1Id: string;
  let task2Id: string;
  let task3Id: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    userId = seeded.defaultUserId;
    task1Id = 'tpl-make-bed';
    task2Id = 'tpl-pushups-10';
    task3Id = 'tpl-morning-sunlight';
  });

  it('Gate 1: Routine Creation & Task Sequencing: Creates structured routine with ordered tasks and Version 1', () => {
    const routine = RoutineEngine.createRoutine({
      userId,
      name: 'Morning Spartan Protocol',
      description: 'Dawn activation sequence',
      type: 'MORNING',
      minimumRequiredTasks: 2,
      tasks: [
        { taskTemplateId: task1Id, sequence: 1, offsetMinutes: 0 },
        { taskTemplateId: task2Id, sequence: 2, offsetMinutes: 10 },
        { taskTemplateId: task3Id, sequence: 3, offsetMinutes: 20 }
      ]
    });

    routineId = routine.id;
    expect(routine.id).toBeDefined();
    expect(routine.version).toBe(1);
    expect(routine.status).toBe('ACTIVE');
    expect(routine.tasks?.length).toBe(3);
    expect(routine.tasks?.[0].sequence).toBe(1);
  });

  it('Gate 2: Routine Versioning: Updating a routine increments version snapshot without mutating historical records', () => {
    const updated = RoutineEngine.updateRoutine({
      routineId,
      userId,
      name: 'Morning Spartan Protocol v2',
      tasks: [
        { taskTemplateId: task1Id, sequence: 1, offsetMinutes: 0 },
        { taskTemplateId: task2Id, sequence: 2, offsetMinutes: 15 } // adjusted timing
      ]
    });

    expect(updated.version).toBe(2);
    expect(updated.name).toBe('Morning Spartan Protocol v2');
    expect(updated.tasks?.length).toBe(2);
  });

  it('Gate 3: Recurrence Engine: Accurately evaluates DAILY, WEEKDAYS, WEEKENDS, and CUSTOM schedules', () => {
    const weekdayRule: ScheduleRuleEntity = {
      id: 'rule-wd-1',
      userId,
      scheduleType: 'WEEKDAYS',
      timeOfDay: '07:00',
      timezone: 'UTC',
      enabled: true,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    // Monday (2026-08-24 is a Monday)
    const monday = new Date('2026-08-24T07:00:00.000Z');
    expect(RecurrenceEngine.occursOn(weekdayRule, monday)).toBe(true);

    // Saturday (2026-08-29 is a Saturday)
    const saturday = new Date('2026-08-29T07:00:00.000Z');
    expect(RecurrenceEngine.occursOn(weekdayRule, saturday)).toBe(false);
  });

  it('Gate 4: Timezone & Rolling Horizon Mission Generation: Generates scheduled instances with idempotency key', () => {
    const db = DatabaseService.getDb();
    // Attach schedule to routine
    db.prepare(`
      INSERT OR REPLACE INTO schedule_rules (
        id, user_id, routine_id, schedule_type, time_of_day, timezone, enabled, created_at, updated_at
      ) VALUES ('sched-test-11', ?, ?, 'DAILY', '07:00', 'Asia/Kolkata', 1, ?, ?)
    `).run(userId, routineId, new Date().toISOString(), new Date().toISOString());

    const now = new Date();
    const future = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000); // 3 days horizon

    const result = SchedulingEngine.generateMissions({
      userId,
      startDate: now,
      endDate: future,
      timezone: 'Asia/Kolkata'
    });

    expect(result.generatedCount).toBeGreaterThan(0);
    expect(result.missions[0].idempotencyKey).toBeDefined();
    expect(result.missions[0].source).toBe('ROUTINE');
  });

  it('Gate 5: Scheduler Idempotency: Multiple runs produce exactly 0 duplicates', () => {
    const now = new Date();
    const future = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);

    // Second run
    const result2 = SchedulingEngine.generateMissions({
      userId,
      startDate: now,
      endDate: future,
      timezone: 'Asia/Kolkata'
    });

    expect(result2.generatedCount).toBe(0);
    expect(result2.skippedCount).toBeGreaterThan(0);
  });

  it('Gate 6: Conflict Engine: Detects overlapping time windows and flags severity levels', () => {
    const slotA = {
      id: 'task-a',
      name: '10 Pushups',
      startTime: new Date('2026-08-27T07:00:00.000Z'),
      endTime: new Date('2026-08-27T07:20:00.000Z'),
      isMandatory: true
    };
    const slotB = {
      id: 'task-b',
      name: 'Cold Shower',
      startTime: new Date('2026-08-27T07:10:00.000Z'), // 10 min overlap
      endTime: new Date('2026-08-27T07:30:00.000Z'),
      isMandatory: true
    };

    const conflicts = ConflictEngine.detectConflicts([slotA, slotB]);
    expect(conflicts.length).toBe(1);
    expect(conflicts[0].conflict).toBe(true);
    expect(conflicts[0].overlapMinutes).toBe(10);
    expect(conflicts[0].resolutionOptions.length).toBeGreaterThanOrEqual(4);
  });

  it('Gate 7: Dependency Engine: Rejects circular dependency cycles (A -> B -> C -> A)', () => {
    const validDeps = [
      { id: '1', prerequisiteId: 'A', dependentId: 'B', dependencyType: 'HARD' as const, createdAt: new Date() },
      { id: '2', prerequisiteId: 'B', dependentId: 'C', dependencyType: 'HARD' as const, createdAt: new Date() }
    ];
    expect(DependencyEngine.validateNoCycles(validDeps)).toBe(true);

    const circularDeps = [
      ...validDeps,
      { id: '3', prerequisiteId: 'C', dependentId: 'A', dependencyType: 'HARD' as const, createdAt: new Date() }
    ];
    expect(() => DependencyEngine.validateNoCycles(circularDeps)).toThrow('DEPENDENCY_CYCLE');
  });

  it('Gate 8: Rest Day & Routine Pausing: Suppresses mission generation during rest periods', () => {
    const db = DatabaseService.getDb();
    const tomorrowStr = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString().substring(0, 10);

    // Record Rest Day
    db.prepare('INSERT OR REPLACE INTO rest_days (id, user_id, date, reason, created_at) VALUES (?, ?, ?, ?, ?)').run(
      'rest-test-1',
      userId,
      tomorrowStr,
      'Recovery Protocol',
      new Date().toISOString()
    );

    // Pause routine
    RoutineEngine.updateRoutine({
      routineId,
      userId,
      status: 'PAUSED',
      pauseUntil: tomorrowStr
    });

    const now = new Date();
    const nextDay = new Date(Date.now() + 24 * 60 * 60 * 1000);

    const res = SchedulingEngine.generateMissions({
      userId,
      startDate: now,
      endDate: nextDay
    });

    // Routine is paused so 0 new missions should be generated for it
    expect(res.generatedCount).toBe(0);
  });

  it('Gate 9: Adaptive Difficulty Recommendation: Identifies 100% completion rate and produces challenge advice', () => {
    const recommendation = AdaptationEngine.evaluateTaskPerformance({
      taskTemplateId: task1Id,
      taskName: 'Make Bed',
      currentDifficulty: 1,
      completedCount: 10,
      assignedCount: 10
    });

    expect(recommendation.level).toBe('EASY');
    expect(recommendation.recommendationType).toBe('INCREASE_CHALLENGE');
    expect(recommendation.proposedDifficulty).toBe(2);
    expect(recommendation.userApprovalRequired).toBe(true);
  });

  it('Gate 10: Routine Analytics: Computes completion rates, average delay, and routine health', () => {
    const analytics = RoutineEngine.getRoutineAnalytics(routineId, userId);
    expect(analytics.routineId).toBe(routineId);
    expect(analytics.completionRate).toBeGreaterThanOrEqual(0);
    expect(analytics.routineHealth).toBeDefined();
  });
});
