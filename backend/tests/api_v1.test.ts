// Integration Tests for Habitat Modular Backend (/api/v1)
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { AlarmsService } from '../src/modules/alarms/alarms.controller';
import { MissionsService } from '../src/modules/missions/missions.controller';
import { ProofsService } from '../src/modules/proofs/proofs.controller';
import { GamificationService } from '../src/modules/gamification/gamification.controller';

describe('Habitat Modular Backend (/api/v1)', () => {
  let defaultUserId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;
  });

  it('loads 10 starter tasks', () => {
    const tasks = TasksService.getAll();
    expect(tasks.length).toBe(10);
    const bedTask = tasks.find((t) => t.slug === 'make-bed');
    expect(bedTask).toBeDefined();
    expect(bedTask?.category).toBe('morning');
  });

  it('creates an alarm commitment', () => {
    const task = TasksService.getAll()[0];
    const alarm = AlarmsService.create({
      userId: defaultUserId,
      taskId: task.id,
      timeOfDay: '07:00',
      repeatDays: [1, 2, 3, 4, 5],
      disciplineMode: 'DISCIPLINE'
    });

    expect(alarm?.id).toBeDefined();
    expect(alarm?.timeOfDay).toBe('07:00:00');
  });

  it('triggers mission and processes proof completion with XP ledger update', async () => {
    const task = TasksService.getAll().find((t) => t.slug === 'make-bed')!;
    
    // 1. Trigger Mission
    const mission = MissionsService.triggerMission({
      userId: defaultUserId,
      taskId: task.id,
      disciplineMode: 'DISCIPLINE'
    });
    expect(mission?.status).toBe('TRIGGERED');

    // 2. Start Mission
    const active = MissionsService.startMission(mission!.id);
    expect(active?.status).toBe('ACTIVE');

    // 3. Submit Valid Proof
    const proofResult = await ProofsService.submitAndVerify({
      missionId: mission!.id,
      mediaType: 'image/jpeg',
      storageKey: '/uploads/proof-bed.jpg',
      capturedAt: new Date().toISOString(),
      deviceTelemetry: { ambientLux: 80, accelerometerMotion: true }
    });

    expect(proofResult.isValid).toBe(true);
    expect(proofResult.rewards.totalXp).toBeGreaterThanOrEqual(task.baseXp);

    // 4. Verify Gamification Overview
    const overview = GamificationService.getOverview(defaultUserId);
    expect(overview.streaks.currentStreak).toBeGreaterThan(0);
    expect(overview.gamification.totalXp).toBeGreaterThan(0);
  });

  it('handles offline sync batch with idempotency deduplication', async () => {
    const task = TasksService.getAll()[1];
    const idempotencyKey = 'c7e5a8f2-4911-477d-815d-16f3c1d9a29e';

    // First Sync Batch
    const mission1 = MissionsService.triggerMission({
      userId: defaultUserId,
      taskId: task.id,
      idempotencyKey
    });

    // Duplicate Sync Batch Attempt (must not duplicate)
    const mission2 = MissionsService.triggerMission({
      userId: defaultUserId,
      taskId: task.id,
      idempotencyKey
    });

    expect(mission1?.id).toBe(mission2?.id);
  });
});
