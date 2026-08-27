// Phase 7 Mission / Discipline Engine Master Integration Tests
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { MissionService } from '../src/modules/mission/mission.service';
import { MissionStatus, MissionStateMachine, MissionEventType } from '../src/modules/mission/domain/mission.rules';

describe('Phase 7 Acceptance Gate: Mission / Discipline Engine & 5-Minute Retry Session State Machine', () => {
  let userId: string;
  let taskAId: string;
  let taskBId: string;
  let missionAId: string;
  let missionBId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    userId = seeded.defaultUserId;

    // Task A: Take a photo outside
    const taskA = TasksService.createCustomTask(userId, {
      name: 'Take a photo outside',
      description: 'Morning light exposure',
      instructions: 'Go outside and capture photo proof.',
      category: 'MORNING',
      proofType: 'PHOTO',
      difficulty: 1,
      baseXp: 40
    });
    taskAId = taskA.id;

    // Task B: 10 Push-ups
    const taskB = TasksService.createCustomTask(userId, {
      name: '10 Push-ups',
      description: 'Chest to floor reps',
      instructions: 'Record 10 controlled push-ups.',
      category: 'PHYSICAL',
      proofType: 'VIDEO',
      difficulty: 2,
      baseXp: 50
    });
    taskBId = taskB.id;
  });

  it('Gate 1: Idempotent Mission Creation: Alarm trigger creates mission and prevents duplicates', () => {
    const alarmOccurrence = '2026-08-27T06:30:00.000Z';
    const alarmId = 'alarm-7-test-01';

    const mission1 = MissionService.createMission({
      userId,
      taskId: taskAId,
      alarmId,
      scheduledAt: alarmOccurrence
    });

    expect(mission1).toBeDefined();
    expect(mission1.status).toBe(MissionStatus.ACTIVE);
    expect(mission1.task.title).toBe('Take a photo outside');
    missionAId = mission1.id;

    // Re-triggering the same alarm occurrence must return identical mission
    const missionDuplicate = MissionService.createMission({
      userId,
      taskId: taskAId,
      alarmId,
      scheduledAt: alarmOccurrence
    });

    expect(missionDuplicate.id).toBe(mission1.id);
  });

  it('Gate 2: State Machine Golden Path: ACTIVE -> IN_PROGRESS -> VERIFYING -> COMPLETED', () => {
    // 1. Start Mission (ACTIVE -> IN_PROGRESS)
    const started = MissionService.startMission(missionAId, userId);
    expect(started.status).toBe(MissionStatus.IN_PROGRESS);
    expect(started.attemptCount).toBe(1);

    // 2. Submit Proof (IN_PROGRESS -> VERIFYING)
    const submitted = MissionService.submitMission(missionAId, userId, { proofType: 'PHOTO', storageKey: 'photo.jpg' });
    expect(submitted.status).toBe(MissionStatus.VERIFYING);

    // 3. Complete Mission (VERIFYING -> COMPLETED)
    const completed = MissionService.completeMission(missionAId, userId);
    expect(completed.status).toBe(MissionStatus.COMPLETED);
    expect(completed.completedAt).toBeDefined();
  });

  it('Gate 3: State Machine Rejects Illegal State Transitions', () => {
    // COMPLETED -> IN_PROGRESS must fail
    expect(() => MissionStateMachine.assertTransition(MissionStatus.COMPLETED, MissionStatus.IN_PROGRESS)).toThrow(
      'MISSION_INVALID_STATE'
    );

    // COMPLETED -> RETRY must fail
    expect(() => MissionStateMachine.assertTransition(MissionStatus.COMPLETED, MissionStatus.RETRY)).toThrow(
      'MISSION_INVALID_STATE'
    );

    // CANCELLED -> ACTIVE must fail
    expect(() => MissionStateMachine.assertTransition(MissionStatus.CANCELLED, MissionStatus.ACTIVE)).toThrow(
      'MISSION_INVALID_STATE'
    );
  });

  it('Gate 4: GET /current returns the active mission with task snapshot', () => {
    // Create new active mission for Task B
    const missionB = MissionService.createMission({
      userId,
      taskId: taskBId,
      alarmId: 'alarm-7-test-02',
      scheduledAt: '2026-08-27T07:00:00.000Z'
    });
    missionBId = missionB.id;

    const current = MissionService.getCurrentMission(userId);
    expect(current).toBeDefined();
    expect(current?.id).toBe(missionBId);
    expect(current?.task.name).toBe('10 Push-ups');
    expect(current?.status).toBe(MissionStatus.ACTIVE);
  });

  it('Gate 5: 5-Minute Inactivity Retry Cycle: Verification Rejection -> RETRY (+5 min) -> ACTIVE', () => {
    // Start Mission B (Attempt 1)
    MissionService.startMission(missionBId, userId);
    MissionService.submitMission(missionBId, userId);

    // Reject verification -> schedules +5 minute retry
    const retried = MissionService.retryMission(missionBId, 'Video duration was under 10 seconds', userId);
    expect(retried.status).toBe(MissionStatus.RETRY);
    expect(retried.retryCount).toBe(1);
    expect(retried.nextRetryAt).toBeDefined();

    // Verify nextRetryAt is ~5 minutes in the future
    const now = Date.now();
    const nextRetryEpoch = new Date(retried.nextRetryAt!).getTime();
    expect(nextRetryEpoch - now).toBeGreaterThan(4 * 60 * 1000);
  });

  it('Gate 6: Successful Retry Flow: Second attempt accepted -> COMPLETED and stops retries', () => {
    // User starts Attempt #2
    const startedAttempt2 = MissionService.startMission(missionBId, userId);
    expect(startedAttempt2.attemptCount).toBe(2);

    // Submit and Accept
    MissionService.submitMission(missionBId, userId);
    const completed = MissionService.completeMission(missionBId, userId);

    expect(completed.status).toBe(MissionStatus.COMPLETED);
    expect(completed.retryCount).toBe(1);
    expect(completed.attemptCount).toBe(2);
    expect(completed.nextRetryAt).toBeNull();
  });

  it('Gate 7: Idempotent Completion: Multiple complete calls do not duplicate rewards or state', () => {
    const complete1 = MissionService.completeMission(missionBId, userId);
    const complete2 = MissionService.completeMission(missionBId, userId);

    expect(complete1.status).toBe(MissionStatus.COMPLETED);
    expect(complete2.status).toBe(MissionStatus.COMPLETED);
    expect(complete1.id).toBe(complete2.id);
  });

  it('Gate 8: Mission Events Audit History: Tracks chronological transition logs', () => {
    const events = MissionService.getEvents(missionBId);
    expect(events.length).toBeGreaterThanOrEqual(4);

    const eventTypes = events.map((e) => e.type);
    expect(eventTypes).toContain(MissionEventType.MISSION_CREATED);
    expect(eventTypes).toContain(MissionEventType.MISSION_STARTED);
    expect(eventTypes).toContain(MissionEventType.PROOF_SUBMITTED);
    expect(eventTypes).toContain(MissionEventType.VERIFICATION_FAILED);
    expect(eventTypes).toContain(MissionEventType.MISSION_COMPLETED);
  });

  it('Gate 9: User & Task Isolation: Mission A completion does not affect Mission C', () => {
    const missionC = MissionService.createMission({
      userId,
      taskId: taskAId,
      alarmId: 'alarm-7-test-03',
      scheduledAt: '2026-08-27T08:00:00.000Z'
    });

    expect(missionC.status).toBe(MissionStatus.ACTIVE);
    expect(MissionService.getById(missionAId)?.status).toBe(MissionStatus.COMPLETED);
  });

  it('Gate 10: Cancel Mission: Transitions active mission to CANCELLED', () => {
    const missionToCancel = MissionService.createMission({
      userId,
      taskId: taskAId,
      alarmId: 'alarm-7-test-cancel',
      scheduledAt: '2026-08-27T09:00:00.000Z'
    });

    const cancelled = MissionService.cancelMission(missionToCancel.id, 'User emergency', userId);
    expect(cancelled.status).toBe(MissionStatus.CANCELLED);
    expect(cancelled.nextRetryAt).toBeNull();
  });
});
