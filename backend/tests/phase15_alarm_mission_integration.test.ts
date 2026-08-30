// Phase 15 Alarm ↔ Mission Native Integration Test Suite
import { describe, it, expect, beforeAll, beforeEach } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { AlarmsService } from '../src/modules/alarms/alarms.controller';
import { AlarmOccurrenceRepository } from '../src/repositories/alarm-occurrence.repository';

describe('Phase 15: Alarm ↔ Mission Native Integration', () => {
  let defaultUserId: string;
  let taskId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;
    taskId = TasksService.getAll()[0].id;
  });

  beforeEach(() => {
    const db = DatabaseService.getDb();
    db.prepare('DELETE FROM alarm_occurrences WHERE user_id = ?').run(defaultUserId);
    db.prepare('DELETE FROM alarms WHERE user_id = ?').run(defaultUserId);
  });

  it('15.1: Schedules alarm commitment and establishes stable alarm identity', () => {
    const alarm = AlarmsService.create({
      userId: defaultUserId,
      taskId,
      timeOfDay: '07:00',
      repeatDays: [1, 2, 3, 4, 5],
      disciplineMode: 'STRICT',
      retryIntervalMinutes: 5
    });

    expect(alarm).toBeDefined();
    expect(alarm?.repeatDays).toEqual([1, 2, 3, 4, 5]);
    expect(alarm?.isEnabled).toBe(true);
  });

  it('15.2: Acknowledges native alarm trigger and records occurrence in ledger', () => {
    const alarm = AlarmsService.create({
      userId: defaultUserId,
      taskId,
      timeOfDay: '06:30',
      repeatDays: [1, 2, 3, 4, 5]
    })!;

    const occurrence = AlarmOccurrenceRepository.create({
      occurrenceId: 'occ_test_01',
      alarmId: alarm.id,
      missionId: 'mission_test_01',
      userId: defaultUserId,
      scheduledAt: new Date().toISOString(),
      platform: 'android'
    });

    expect(occurrence.status).toBe('SCHEDULED');

    // Simulate Native AlarmManager Trigger
    AlarmOccurrenceRepository.markTriggered('occ_test_01');

    const triggeredOcc = AlarmOccurrenceRepository.findById('occ_test_01');
    expect(triggeredOcc?.status).toBe('TRIGGERED');
    expect(triggeredOcc?.triggeredAt).toBeDefined();
  });

  it('15.3: Increments retries on native 5-minute escalation', () => {
    const alarm = AlarmsService.create({
      userId: defaultUserId,
      taskId,
      timeOfDay: '07:15',
      repeatDays: [1, 2, 3, 4, 5]
    })!;

    const occurrence = AlarmOccurrenceRepository.create({
      occurrenceId: 'occ_retry_test',
      alarmId: alarm.id,
      missionId: `mission_${alarm.id}_retry`,
      userId: defaultUserId,
      scheduledAt: new Date().toISOString(),
      platform: 'android'
    });

    // Attempt 1 -> 2
    AlarmOccurrenceRepository.incrementRetry('occ_retry_test');
    let occ = AlarmOccurrenceRepository.findById('occ_retry_test');
    expect(occ?.retryCount).toBe(1);
    expect(occ?.status).toBe('RETRYING');

    // Attempt 2 -> 3
    AlarmOccurrenceRepository.incrementRetry('occ_retry_test');
    occ = AlarmOccurrenceRepository.findById('occ_retry_test');
    expect(occ?.retryCount).toBe(2);
  });

  it('15.4: Completes mission and disarms occurrence, preventing subsequent retries', () => {
    const alarm = AlarmsService.create({
      userId: defaultUserId,
      taskId,
      timeOfDay: '07:45',
      repeatDays: [1, 2, 3, 4, 5]
    })!;

    const occurrence = AlarmOccurrenceRepository.create({
      occurrenceId: 'occ_disarm_test',
      alarmId: alarm.id,
      missionId: `mission_${alarm.id}_disarm`,
      userId: defaultUserId,
      scheduledAt: new Date().toISOString(),
      platform: 'android'
    });

    AlarmOccurrenceRepository.markTriggered('occ_disarm_test');
    AlarmOccurrenceRepository.markMissionStarted('occ_disarm_test');

    const completedAt = new Date().toISOString();
    AlarmOccurrenceRepository.markDisarmed('occ_disarm_test', completedAt);

    const disarmedOcc = AlarmOccurrenceRepository.findById('occ_disarm_test');
    expect(disarmedOcc?.status).toBe('DISARMED');
    expect(disarmedOcc?.completedAt).toBe(completedAt);
  });

  it('15.5: Isolates recurring alarm occurrences with unique mission IDs', () => {
    const alarm = AlarmsService.create({
      userId: defaultUserId,
      taskId,
      timeOfDay: '08:00',
      repeatDays: [1, 2, 3]
    })!;

    // Monday occurrence
    const occMonday = AlarmOccurrenceRepository.create({
      occurrenceId: 'occ_mon',
      alarmId: alarm.id,
      missionId: `mission_${alarm.id}_20260831`,
      userId: defaultUserId,
      scheduledAt: '2026-08-31T08:00:00.000Z'
    });

    // Tuesday occurrence
    const occTuesday = AlarmOccurrenceRepository.create({
      occurrenceId: 'occ_tue',
      alarmId: alarm.id,
      missionId: `mission_${alarm.id}_20260901`,
      userId: defaultUserId,
      scheduledAt: '2026-09-01T08:00:00.000Z'
    });

    expect(occMonday.missionId).not.toBe(occTuesday.missionId);

    const occurrences = AlarmOccurrenceRepository.findByAlarmId(alarm.id);
    expect(occurrences.length).toBe(2);
  });
});
