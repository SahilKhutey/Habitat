// Phase 3 Backend & Database Foundation Repository Layer Integration Tests
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { UserRepository } from '../src/repositories/user.repository';
import { TaskRepository } from '../src/repositories/task.repository';
import { AlarmRepository } from '../src/repositories/alarm.repository';
import { MissionRepository } from '../src/repositories/mission.repository';
import { GamificationRepository } from '../src/repositories/gamification.repository';

describe('Phase 3 Acceptance: Clean Architecture Repository Layer', () => {
  let createdUserId: string;
  let createdTaskId: string;
  let createdAlarmId: string;
  let createdMissionId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
  });

  it('creates and finds a user via UserRepository', () => {
    const user = UserRepository.create({
      email: 'marcus.aurelius@discipline.io',
      passwordHash: 'hashed_password_123',
      displayName: 'Marcus Aurelius',
      timezone: 'Europe/Rome'
    });

    expect(user).toBeDefined();
    expect(user.email).toBe('marcus.aurelius@discipline.io');
    expect(user.disciplineScore).toBe(100);
    createdUserId = user.id;

    const found = UserRepository.findById(createdUserId);
    expect(found?.displayName).toBe('Marcus Aurelius');

    const byEmail = UserRepository.findByEmail('marcus.aurelius@discipline.io');
    expect(byEmail?.id).toBe(createdUserId);
  });

  it('creates and queries tasks via TaskRepository', () => {
    const task = TaskRepository.create({
      userId: createdUserId,
      slug: 'morning-stoic-journal',
      title: 'Morning Stoic Journal',
      description: 'Write 3 intentions for the day in physical notebook',
      category: 'mindfulness',
      difficulty: 'EASY',
      proofType: 'PHOTO',
      baseXp: 40,
      estimatedDurationSec: 120,
      instructions: 'Capture photo of journal with legible handwriting',
      validationRules: { minLux: 30 }
    });

    expect(task).toBeDefined();
    expect(task.slug).toBe('morning-stoic-journal');
    expect(task.validationRules.minLux).toBe(30);
    createdTaskId = task.id;

    const allTasks = TaskRepository.findAll();
    expect(allTasks.length).toBeGreaterThanOrEqual(1);
  });

  it('creates and lists user alarm commitments via AlarmRepository', () => {
    const alarm = AlarmRepository.create({
      userId: createdUserId,
      taskId: createdTaskId,
      timeOfDay: '06:30',
      repeatDays: [1, 2, 3, 4, 5],
      disciplineMode: 'HARDCORE',
      retryIntervalMinutes: 3
    });

    expect(alarm).toBeDefined();
    expect(alarm.timeOfDay).toBe('06:30:00');
    expect(alarm.disciplineMode).toBe('HARDCORE');
    createdAlarmId = alarm.id;

    const userAlarms = AlarmRepository.findByUserId(createdUserId);
    expect(userAlarms.length).toBe(1);
  });

  it('triggers and tracks mission state via MissionRepository', () => {
    const mission = MissionRepository.create({
      userId: createdUserId,
      taskId: createdTaskId,
      alarmId: createdAlarmId,
      disciplineMode: 'HARDCORE',
      idempotencyKey: 'mission-phase3-dedup-01'
    });

    expect(mission).toBeDefined();
    expect(mission.status).toBe('TRIGGERED');
    createdMissionId = mission.id;

    const duplicate = MissionRepository.findByIdempotencyKey('mission-phase3-dedup-01');
    expect(duplicate?.id).toBe(createdMissionId);

    MissionRepository.updateStatus(createdMissionId, 'COMPLETED', new Date().toISOString(), 84);
    const updated = MissionRepository.findById(createdMissionId);
    expect(updated?.status).toBe('COMPLETED');
    expect(updated?.resistanceSeconds).toBe(84);
  });

  it('manages XP ledger and streaks via GamificationRepository', () => {
    const initialStreak = GamificationRepository.getStreak(createdUserId);
    expect(initialStreak.currentStreak).toBe(0);
    expect(initialStreak.graceTokens).toBe(1);

    GamificationRepository.addXpTransaction({
      userId: createdUserId,
      missionId: createdMissionId,
      amount: 60,
      reason: 'MISSION_COMPLETED'
    });

    const totalXp = GamificationRepository.getTotalXp(createdUserId);
    expect(totalXp).toBe(60);
  });
});
