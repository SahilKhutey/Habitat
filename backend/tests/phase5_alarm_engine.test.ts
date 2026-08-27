// Phase 5 Scheduling & Alarm Engine Master Integration Tests
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { AlarmsService } from '../src/modules/alarms/alarms.controller';
import { AlarmSchedulerService } from '../src/modules/alarms/alarm-scheduler.service';
import { UserRepository } from '../src/repositories/user.repository';
import { TaskRepository } from '../src/repositories/task.repository';

describe('Phase 5 Acceptance Gate: Scheduling & Alarm Engine', () => {
  let userAId: string;
  let userBId: string;
  let taskAId: string;
  let alarmAId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    userAId = seeded.defaultUserId;

    const userB = UserRepository.create({
      email: 'user.b.alarms@discipline.app',
      passwordHash: 'hashed_password_b',
      displayName: 'User Beta'
    });
    userBId = userB.id;

    const taskA = TaskRepository.create({
      userId: userAId,
      slug: 'alarm-test-pushups',
      title: '10 Push-Ups',
      description: 'Morning physical test',
      category: 'physical',
      proofType: 'VIDEO',
      baseXp: 30
    });
    taskAId = taskA.id;
  });

  it('Gate 1: Creates a recurring alarm commitment with repeat days and discipline mode', () => {
    const alarm = AlarmsService.create({
      userId: userAId,
      taskId: taskAId,
      timeOfDay: '07:00',
      repeatDays: [1, 2, 3, 4, 5],
      disciplineMode: 'HARDCORE',
      retryIntervalMinutes: 3,
      timezone: 'America/New_York'
    });

    expect(alarm).toBeDefined();
    expect(alarm?.timeOfDay).toBe('07:00:00');
    expect(alarm?.repeatDays).toEqual([1, 2, 3, 4, 5]);
    expect(alarm?.disciplineMode).toBe('HARDCORE');
    expect(alarm?.retryIntervalMinutes).toBe(3);
    expect(alarm?.isEnabled).toBe(true);

    alarmAId = alarm!.id;
  });

  it('Gate 2: Computes next occurrence accurately for recurring weekday alarms', () => {
    const nextInfo = AlarmSchedulerService.calculateNextOccurrence({
      timeOfDay: '07:00:00',
      repeatDays: [1, 2, 3, 4, 5],
      timezone: 'America/New_York'
    });

    expect(nextInfo.nextOccurrence).toBeDefined();
    expect(nextInfo.secondsUntil).toBeGreaterThanOrEqual(0);
  });

  it('Gate 3: Computes next occurrence for one-off single-shot alarms', () => {
    const nextOneOff = AlarmSchedulerService.calculateNextOccurrence({
      timeOfDay: '08:30:00',
      repeatDays: []
    });

    expect(nextOneOff.nextOccurrence).toBeDefined();
    expect(nextOneOff.secondsUntil).toBeGreaterThan(0);
  });

  it('Gate 4: Toggles alarm enabled state (armed vs disarmed)', () => {
    const disarmed = AlarmsService.toggle(alarmAId);
    expect(disarmed?.isEnabled).toBe(false);

    const armed = AlarmsService.toggle(alarmAId);
    expect(armed?.isEnabled).toBe(true);
  });

  it('Gate 5: Updates alarm parameters without recreating entity', () => {
    const updated = AlarmsService.update(alarmAId, {
      timeOfDay: '06:45',
      disciplineMode: 'DISCIPLINE',
      retryIntervalMinutes: 5
    });

    expect(updated?.timeOfDay).toBe('06:45:00');
    expect(updated?.disciplineMode).toBe('DISCIPLINE');
    expect(updated?.retryIntervalMinutes).toBe(5);
  });

  it('Gate 6: Evaluates psychoacoustic volume escalation levels across attempts', () => {
    const vol1 = AlarmSchedulerService.getEscalationVolume(1, 'DISCIPLINE');
    const vol2 = AlarmSchedulerService.getEscalationVolume(2, 'DISCIPLINE');
    const vol3 = AlarmSchedulerService.getEscalationVolume(3, 'DISCIPLINE');

    expect(vol1).toBe(70);
    expect(vol2).toBe(85);
    expect(vol3).toBe(95);

    const hardVol3 = AlarmSchedulerService.getEscalationVolume(3, 'HARDCORE');
    expect(hardVol3).toBe(100);
  });

  it('Gate 7: Fetches the earliest upcoming alarm using getNextAlarm', () => {
    const next = AlarmsService.getNextAlarm(userAId);
    expect(next).toBeDefined();
    expect(next?.alarm.id).toBe(alarmAId);
    expect(next?.nextOccurrence).toBeDefined();
  });

  it('Gate 8: Deletes alarm and cleans up scheduling', () => {
    const deleted = AlarmsService.delete(alarmAId);
    expect(deleted).toBe(true);

    const check = AlarmsService.getById(alarmAId);
    expect(check).toBeNull();
  });
});
