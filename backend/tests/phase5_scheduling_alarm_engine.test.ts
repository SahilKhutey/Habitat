// Phase 5 Scheduling & Alarm Engine Deep Integration Test Suite
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { SchedulingService } from '../src/modules/scheduling/scheduling.controller';
import { ScheduleCalculator } from '../src/modules/scheduling/schedule-calculator';
import { RetryEngine } from '../src/modules/scheduling/retry-engine';
import { MissionsService } from '../src/modules/missions/missions.controller';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { UserRepository } from '../src/repositories/user.repository';

describe('Phase 5 Acceptance Gate: Stateful Alarm Engine & 5-Minute Retry Session Loop', () => {
  let userId: string;
  let taskId: string;
  let scheduleId: string;
  let missionId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    userId = seeded.defaultUserId;

    const task = TasksService.createCustomTask(userId, {
      name: 'Cold Water Face Splash',
      description: 'Splash icy water 5 times to activate vagus nerve',
      instructions: 'Snap photo of water at sink',
      category: 'HEALTH',
      proofType: 'PHOTO',
      difficulty: 1,
      baseXp: 20
    });
    taskId = task.id;
  });

  it('Gate 1: Calculates next occurrence across timezones and repeat day sets', () => {
    const nextDaily = ScheduleCalculator.calculateNextOccurrence({
      startTime: '06:30',
      repeatType: 'DAILY',
      timezone: 'America/New_York'
    });
    expect(nextDaily.nextOccurrence).toBeDefined();
    expect(nextDaily.secondsUntil).toBeGreaterThanOrEqual(0);

    const nextWeekly = ScheduleCalculator.calculateNextOccurrence({
      startTime: '07:00',
      repeatType: 'WEEKLY',
      daysOfWeek: ['MONDAY', 'WEDNESDAY', 'FRIDAY'],
      timezone: 'Asia/Kolkata'
    });
    expect(nextWeekly.nextOccurrence).toBeDefined();
  });

  it('Gate 2: Creates an alarm schedule commitment bound to task', () => {
    const schedule = SchedulingService.createSchedule(userId, {
      taskId,
      startTime: '07:00',
      repeatType: 'CUSTOM',
      daysOfWeek: ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY'],
      timezone: 'America/New_York',
      retryIntervalMinutes: 5
    });

    expect(schedule).toBeDefined();
    expect(schedule.startTime).toBe('07:00');
    expect(schedule.isEnabled).toBe(true);
    expect(schedule.nextOccurrence).toBeDefined();

    scheduleId = schedule.id;
  });

  it('Gate 3: Generates mission snapshot idempotently (preventing duplicate missions)', () => {
    const scheduledDate = '2026-08-27T07:00:00.000Z';
    const mission1 = SchedulingService.generateMissionForSchedule(scheduleId, scheduledDate);
    expect(mission1).toBeDefined();
    expect(mission1.status).toBe('SCHEDULED');

    missionId = mission1.id;

    // Second call on same occurrence must return existing mission without duplication
    const mission2 = SchedulingService.generateMissionForSchedule(scheduleId, scheduledDate);
    expect(mission2.id).toBe(mission1.id);
  });

  it('Gate 4: 5-Minute Inactivity Escalation: Progressively schedules Attempt #2 (85dB) and Attempt #3 (100dB)', () => {
    // Attempt #1 is initial (70dB)
    const attempt2 = RetryEngine.processNextAttempt(missionId, 5);
    expect(attempt2).toBeDefined();
    expect(attempt2?.attemptNumber).toBe(2);

    const attempt3 = RetryEngine.processNextAttempt(missionId, 5);
    expect(attempt3).toBeDefined();
    expect(attempt3?.attemptNumber).toBe(3);

    const mission = MissionsService.getById(missionId);
    expect(mission?.attemptCount).toBe(3);
    expect(mission?.status).toBe('ACTIVE');
  });

  it('Gate 5: Mission completion atomically cancels all future retry attempts', () => {
    // Complete the mission
    MissionsService.completeMission(missionId, 180);

    const mission = MissionsService.getById(missionId);
    expect(mission?.status).toBe('COMPLETED');

    // Trying to schedule another retry after completion returns null and cancels pending
    const postCompleteRetry = RetryEngine.processNextAttempt(missionId, 5);
    expect(postCompleteRetry).toBeNull();
  });

  it('Gate 6: Reconciles active alarms via sync endpoint (GET /api/v1/sync/alarms)', () => {
    const sync = SchedulingService.getSyncAlarms(userId);
    expect(sync.serverTime).toBeDefined();
    expect(Array.isArray(sync.activeAlarms)).toBe(true);
  });

  it('Gate 7: Paused task halts future mission generation', () => {
    // Pause the bound task
    TasksService.setTaskStatus(taskId, userId, 'PAUSED');

    const futureDate = '2026-08-28T07:00:00.000Z';
    const mission = SchedulingService.generateMissionForSchedule(scheduleId, futureDate);
    expect(mission).toBeNull(); // No mission generated for paused task
  });
});
