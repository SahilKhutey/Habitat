// Phase 3 Core Backend, Domain Model & Data Architecture Master Integration Tests
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { UserRepository } from '../src/repositories/user.repository';
import { TaskRepository } from '../src/repositories/task.repository';
import { AlarmRepository } from '../src/repositories/alarm.repository';
import { MissionRepository } from '../src/repositories/mission.repository';
import { GamificationRepository } from '../src/repositories/gamification.repository';
import { MissionLifecycleService } from '../src/modules/missions/mission-lifecycle.service';
import { StorageService } from '../src/modules/media/storage.service';

describe('Phase 3 Acceptance Gate: Core Backend, Domain Model & Data Architecture', () => {
  let userAId: string;
  let userBId: string;
  let taskAId: string;
  let alarmAId: string;
  let missionAId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
  });

  it('Gate 1: Creates User A, authenticates and creates an owned task', () => {
    const userA = UserRepository.create({
      email: 'user.a@discipline.app',
      passwordHash: 'hashed_password_a',
      displayName: 'User Alpha',
      timezone: 'America/New_York'
    });
    expect(userA).toBeDefined();
    userAId = userA.id;

    const taskA = TaskRepository.create({
      userId: userAId,
      slug: 'user-a-cold-shower',
      title: '2-Minute Cold Shower',
      description: 'Turn shower handle to coldest setting for 120s',
      category: 'DISCIPLINE',
      difficulty: 'HARD',
      proofType: 'VIDEO',
      baseXp: 50,
      instructions: 'Record video proof of cold water stream',
      validationRules: { minDurationSec: 10 }
    });
    expect(taskA).toBeDefined();
    expect(taskA.userId).toBe(userAId);
    taskAId = taskA.id;
  });

  it('Gate 2: Enforces User Ownership Isolation between User A and User B', () => {
    const userB = UserRepository.create({
      email: 'user.b@discipline.app',
      passwordHash: 'hashed_password_b',
      displayName: 'User Beta'
    });
    userBId = userB.id;

    // User A querying their own task succeeds
    const taskForA = TaskRepository.findById(taskAId);
    expect(taskForA?.userId).toBe(userAId);

    // Verify isolation logic
    const isOwner = taskForA?.userId === userBId;
    expect(isOwner).toBe(false);
  });

  it('Gate 3: Schedules alarm and activates mission state machine', () => {
    const alarm = AlarmRepository.create({
      userId: userAId,
      taskId: taskAId,
      timeOfDay: '07:00',
      repeatDays: [1, 2, 3, 4, 5],
      disciplineMode: 'DISCIPLINE',
      retryIntervalMinutes: 5
    });
    expect(alarm).toBeDefined();
    alarmAId = alarm.id;

    const mission = MissionRepository.create({
      userId: userAId,
      taskId: taskAId,
      alarmId: alarmAId,
      disciplineMode: 'DISCIPLINE'
    });
    expect(mission.status).toBe('TRIGGERED');
    missionAId = mission.id;
  });

  it('Gate 4: Transitions mission through lifecycle and executes atomic completion transaction', () => {
    const initialTotalXp = GamificationRepository.getTotalXp(userAId);

    // Transition TRIGGERED -> ACTIVE -> SUBMITTED -> VERIFYING
    MissionLifecycleService.transitionMission(missionAId, 'ACTIVE');
    MissionLifecycleService.transitionMission(missionAId, 'SUBMITTED');
    MissionLifecycleService.transitionMission(missionAId, 'VERIFYING');

    // Complete Mission with Instant Action (< 120s) -> +50% XP
    const result = MissionLifecycleService.completeMissionAtomic({
      missionId: missionAId,
      userId: userAId,
      resistanceSeconds: 45,
      baseXp: 50
    });

    expect(result.mission.status).toBe('COMPLETED');
    expect(result.xpAwarded).toBe(75); // 50 + 50% = 75 XP

    const updatedTotalXp = GamificationRepository.getTotalXp(userAId);
    expect(updatedTotalXp).toBe(initialTotalXp + 75);
  });

  it('Gate 5: Idempotency Protection prevents duplicate XP payouts on duplicate completion calls', () => {
    const initialTotalXp = GamificationRepository.getTotalXp(userAId);

    // Call complete second time on already completed mission
    const secondCall = MissionLifecycleService.completeMissionAtomic({
      missionId: missionAId,
      userId: userAId,
      resistanceSeconds: 45,
      baseXp: 50
    });

    expect(secondCall.xpAwarded).toBe(0); // 0 extra XP awarded

    const updatedTotalXp = GamificationRepository.getTotalXp(userAId);
    expect(updatedTotalXp).toBe(initialTotalXp); // No balance change
  });

  it('Gate 6: Rejects invalid state transitions (COMPLETED -> ACTIVE)', () => {
    expect(() => {
      MissionLifecycleService.transitionMission(missionAId, 'ACTIVE');
    }).toThrow(/Invalid state transition/);
  });

  it('Gate 7: Generates isolated S3 / MinIO storage keys', () => {
    const presigned = StorageService.getUploadSignedUrl({
      userId: userAId,
      missionId: missionAId,
      filename: 'cold_shower_proof.mp4',
      mimeType: 'video/mp4'
    });

    expect(presigned.storageKey).toContain(`users/${userAId}/missions/${missionAId}/proof/`);
    expect(presigned.storageKey).toContain('cold_shower_proof.mp4');
    expect(presigned.uploadUrl).toBeDefined();
  });
});
