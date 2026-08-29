// Unit Tests: Alarm Occurrence Audit Trail & Observability
import { describe, it, expect, beforeEach } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { AlarmOccurrenceRepository } from '../src/repositories/alarm-occurrence.repository';

describe('Alarm Occurrence Audit Trail & Observability', () => {
  const userId = 'user-obs-1';
  const alarmId = 'alarm-obs-1';
  const missionId = 'mission-obs-1';

  beforeEach(() => {
    DatabaseService.resetDbForTesting();
    const db = DatabaseService.getDb();

    db.prepare(`
      INSERT INTO users (id, email, password_hash, display_name, created_at, updated_at)
      VALUES (?, 'obs@habitat.com', 'h', 'Observability User', datetime('now'), datetime('now'))
    `).run(userId);

    db.prepare(`
      INSERT INTO tasks (id, slug, title, description, instructions, category, proof_type, validation_rules, created_at)
      VALUES ('task-obs', 'obs-task', 'Water', 'Drink water', 'Full', 'MORNING', 'PHOTO', '{}', datetime('now'))
    `).run();

    db.prepare(`
      INSERT INTO alarms (id, user_id, task_id, time_of_day, timezone, repeat_days, created_at, updated_at)
      VALUES (?, ?, 'task-obs', '06:30:00', 'UTC', '[1,2,3,4,5]', datetime('now'), datetime('now'))
    `).run(alarmId, userId);

    db.prepare(`
      INSERT INTO missions (id, user_id, task_id, alarm_id, scheduled_at, status, created_at)
      VALUES (?, ?, 'task-obs', ?, datetime('now'), 'SCHEDULED', datetime('now'))
    `).run(missionId, userId, alarmId);
  });

  it('records complete occurrence lifecycle and provides root-cause answers for missed alarms', () => {
    const scheduledAt = '2026-08-29T06:30:00.000Z';

    // 1. Scheduler registers occurrence
    const occ = AlarmOccurrenceRepository.create({
      alarmId,
      missionId,
      userId,
      scheduledAt,
      platform: 'android'
    });

    expect(occ.occurrenceId).toBeDefined();
    expect(occ.status).toBe('SCHEDULED');
    expect(occ.retryCount).toBe(0);
    expect(occ.schedulerRegisteredAt).toBeDefined();

    // 2. Alarm fires at scheduled time
    AlarmOccurrenceRepository.markTriggered(occ.occurrenceId);
    let current = AlarmOccurrenceRepository.findById(occ.occurrenceId);
    expect(current?.status).toBe('TRIGGERED');
    expect(current?.triggeredAt).toBeDefined();

    // 3. User opens app and starts mission
    AlarmOccurrenceRepository.markMissionStarted(occ.occurrenceId);
    current = AlarmOccurrenceRepository.findById(occ.occurrenceId);
    expect(current?.missionStartedAt).toBeDefined();

    // 4. Escalation retry occurs
    AlarmOccurrenceRepository.incrementRetry(occ.occurrenceId);
    current = AlarmOccurrenceRepository.findById(occ.occurrenceId);
    expect(current?.status).toBe('RETRYING');
    expect(current?.retryCount).toBe(1);

    // 5. User finishes task and disarms alarm
    AlarmOccurrenceRepository.markDisarmed(occ.occurrenceId);
    current = AlarmOccurrenceRepository.findById(occ.occurrenceId);
    expect(current?.status).toBe('DISARMED');
    expect(current?.completedAt).toBeDefined();
  });

  it('records failure reason when alarm is missed due to OEM battery kill', () => {
    const occ = AlarmOccurrenceRepository.create({
      alarmId,
      missionId,
      userId,
      scheduledAt: '2026-08-29T07:00:00.000Z',
      platform: 'android'
    });

    const rootCause = 'Samsung Sleeping Apps terminated foreground service before trigger window';
    AlarmOccurrenceRepository.markMissed(occ.occurrenceId, rootCause);

    const missedOcc = AlarmOccurrenceRepository.findById(occ.occurrenceId);
    expect(missedOcc?.status).toBe('MISSED');
    expect(missedOcc?.failureReason).toBe(rootCause);
  });
});
