// Integration Tests for Phase 05: Alarm Engine & Recurrence Scheduler
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { AlarmsService } from '../src/modules/alarms/alarms.controller';

describe('Phase 05: Alarm Engine & Recurrence Scheduler', () => {
  let defaultUserId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;
  });

  it('creates and lists user alarm commitments with joined task metadata', () => {
    const task = TasksService.getAll()[0];
    const alarm = AlarmsService.create({
      userId: defaultUserId,
      taskId: task.id,
      timeOfDay: '07:30',
      repeatDays: [1, 2, 3, 4, 5],
      disciplineMode: 'DISCIPLINE',
      retryIntervalMinutes: 5
    });

    expect(alarm).toBeDefined();
    expect(alarm?.timeOfDay).toBe('07:30:00');
    expect(alarm?.taskTitle).toBe(task.title);
    expect(alarm?.repeatDays).toEqual([1, 2, 3, 4, 5]);
    expect(alarm?.isEnabled).toBe(true);

    const userAlarms = AlarmsService.getAll(defaultUserId);
    expect(userAlarms.length).toBeGreaterThan(0);
    const found = userAlarms.find((a) => a.id === alarm?.id);
    expect(found).toBeDefined();
  });

  it('toggles alarm enabled state', () => {
    const task = TasksService.getAll()[1];
    const alarm = AlarmsService.create({
      userId: defaultUserId,
      taskId: task.id,
      timeOfDay: '08:15',
      repeatDays: [6, 7], // Weekends
      disciplineMode: 'HARDCORE'
    });

    expect(alarm?.isEnabled).toBe(true);

    // Toggle Off
    const disabled = AlarmsService.toggle(alarm!.id);
    expect(disabled?.isEnabled).toBe(false);

    // Toggle On
    const enabled = AlarmsService.toggle(alarm!.id);
    expect(enabled?.isEnabled).toBe(true);
  });

  it('updates alarm schedule, repeat days, and discipline mode', () => {
    const task = TasksService.getAll()[2];
    const alarm = AlarmsService.create({
      userId: defaultUserId,
      taskId: task.id,
      timeOfDay: '06:00',
      repeatDays: [1, 3, 5]
    });

    const updated = AlarmsService.update(alarm!.id, {
      timeOfDay: '06:15',
      repeatDays: [1, 2, 3, 4, 5, 6, 7],
      disciplineMode: 'HARDCORE',
      retryIntervalMinutes: 3
    });

    expect(updated?.timeOfDay).toBe('06:15:00');
    expect(updated?.repeatDays.length).toBe(7);
    expect(updated?.disciplineMode).toBe('HARDCORE');
    expect(updated?.retryIntervalMinutes).toBe(3);
  });

  it('computes next upcoming alarm correctly', () => {
    const nextInfo = AlarmsService.getNextAlarm(defaultUserId);
    expect(nextInfo).toBeDefined();
    expect(nextInfo?.alarm).toBeDefined();
    expect(nextInfo?.nextOccurrence).toBeDefined();
    expect(new Date(nextInfo!.nextOccurrence).getTime()).toBeGreaterThan(Date.now() - 60000);
  });

  it('deletes an alarm commitment', () => {
    const task = TasksService.getAll()[3];
    const alarm = AlarmsService.create({
      userId: defaultUserId,
      taskId: task.id,
      timeOfDay: '09:00'
    });

    const deleted = AlarmsService.delete(alarm!.id);
    expect(deleted).toBe(true);

    const check = AlarmsService.getById(alarm!.id);
    expect(check).toBeNull();
  });
});
