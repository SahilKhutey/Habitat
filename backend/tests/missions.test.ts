// Integration Tests for Phase 06: Mission Engine & State Machine
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { MissionsService } from '../src/modules/missions/missions.controller';

describe('Phase 06: Mission Engine & State Machine', () => {
  let defaultUserId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;
  });

  it('triggers mission and initializes attempt 1 with 70dB volume', () => {
    const task = TasksService.getAll()[0];
    const mission = MissionsService.triggerMission({
      userId: defaultUserId,
      taskId: task.id,
      disciplineMode: 'DISCIPLINE'
    });

    expect(mission).toBeDefined();
    expect(mission?.status).toBe('TRIGGERED');
    expect(mission?.attemptCount).toBe(1);

    const attempts = MissionsService.getAttempts(mission!.id);
    expect(attempts.length).toBe(1);
    expect(attempts[0].attempt_index).toBe(1);
    expect(attempts[0].siren_volume_level).toBe(70);
  });

  it('transitions triggered mission to ACTIVE', () => {
    const task = TasksService.getAll()[1];
    const mission = MissionsService.triggerMission({
      userId: defaultUserId,
      taskId: task.id
    });

    const active = MissionsService.startMission(mission!.id);
    expect(active?.status).toBe('ACTIVE');
  });

  it('escalates siren volume through multiple 5-minute retry intervals', () => {
    const task = TasksService.getAll()[2];
    const mission = MissionsService.triggerMission({
      userId: defaultUserId,
      taskId: task.id
    });

    // 1st Retry (5 minutes elapsed) -> Attempt 2 @ 85% volume
    const retry1 = MissionsService.retryMission(mission!.id);
    expect(retry1?.status).toBe('RETRYING');
    expect(retry1?.attemptCount).toBe(2);

    // 2nd Retry (10 minutes elapsed) -> Attempt 3 @ 100% volume
    const retry2 = MissionsService.retryMission(mission!.id);
    expect(retry2?.status).toBe('RETRYING');
    expect(retry2?.attemptCount).toBe(3);

    // Inspect attempts history
    const attempts = MissionsService.getAttempts(mission!.id);
    expect(attempts.length).toBe(3);
    expect(attempts[0].siren_volume_level).toBe(70);
    expect(attempts[1].siren_volume_level).toBe(85);
    expect(attempts[2].siren_volume_level).toBe(100);
  });

  it('completes mission, records resistance seconds and resolves attempts', () => {
    const task = TasksService.getAll()[3];
    const pastSchedule = new Date(Date.now() - 90000).toISOString(); // 90 seconds ago

    const mission = MissionsService.triggerMission({
      userId: defaultUserId,
      taskId: task.id,
      scheduledAt: pastSchedule
    });

    const completed = MissionsService.completeMission(mission!.id);
    expect(completed?.status).toBe('COMPLETED');
    expect(completed?.completedAt).toBeDefined();
    expect(completed?.resistanceSeconds).toBeGreaterThanOrEqual(80);

    const attempts = MissionsService.getAttempts(mission!.id);
    const lastAttempt = attempts[attempts.length - 1];
    expect(lastAttempt.status).toBe('COMPLETED');
    expect(lastAttempt.resolved_at).toBeDefined();
  });
});
