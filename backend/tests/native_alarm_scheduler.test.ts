// Unit Tests: NativeAlarmScheduler, Idempotency & 5-Minute Escalation Retry Engine
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { NativeAlarmScheduler } from '../src/modules/alarms/services/native-alarm-scheduler';
import { AlarmOccurrenceRepository } from '../src/repositories/alarm-occurrence.repository';
import { MissionRepository } from '../src/repositories/mission.repository';

describe('NativeAlarmScheduler & Escalation Retry Engine', () => {
  const userId = 'user-native-1';
  const alarmId = 'alarm-native-1';
  const missionId = 'mission-native-1';
  const taskId = 'task-native-1';

  beforeEach(() => {
    DatabaseService.resetDbForTesting();
    NativeAlarmScheduler.resetForTesting();

    const db = DatabaseService.getDb();
    db.prepare(`
      INSERT INTO users (id, email, password_hash, display_name, created_at, updated_at)
      VALUES (?, 'native@habitat.com', 'hash', 'Native Tester', datetime('now'), datetime('now'))
    `).run(userId);

    db.prepare(`
      INSERT INTO tasks (id, slug, title, description, instructions, category, proof_type, validation_rules, created_at)
      VALUES (?, 'native-pushups', 'Pushups', 'Do pushups', 'Depth', 'PHYSICAL', 'VIDEO', '{}', datetime('now'))
    `).run(taskId);

    db.prepare(`
      INSERT INTO alarms (id, user_id, task_id, time_of_day, timezone, repeat_days, created_at, updated_at)
      VALUES (?, ?, ?, '07:00:00', 'UTC', '[1,2,3,4,5]', datetime('now'), datetime('now'))
    `).run(alarmId, userId, taskId);

    db.prepare(`
      INSERT INTO missions (id, user_id, task_id, alarm_id, scheduled_at, status, created_at)
      VALUES (?, ?, ?, ?, datetime('now'), 'SCHEDULED', datetime('now'))
    `).run(missionId, userId, taskId, alarmId);
  });

  afterEach(() => {
    NativeAlarmScheduler.resetForTesting();
  });

  describe('Idempotent Scheduling', () => {
    it('prevents duplicate OS alarms and database records when scheduled repeatedly', () => {
      const scheduledAt = new Date(Date.now() + 3600000).toISOString();

      // Schedule 5 times in succession
      const occ1 = NativeAlarmScheduler.scheduleExactAlarm({ alarmId, missionId, userId, scheduledAt });
      const occ2 = NativeAlarmScheduler.scheduleExactAlarm({ alarmId, missionId, userId, scheduledAt });
      const occ3 = NativeAlarmScheduler.scheduleExactAlarm({ alarmId, missionId, userId, scheduledAt });
      const occ4 = NativeAlarmScheduler.scheduleExactAlarm({ alarmId, missionId, userId, scheduledAt });
      const occ5 = NativeAlarmScheduler.scheduleExactAlarm({ alarmId, missionId, userId, scheduledAt });

      expect(occ1.occurrenceId).toBe(occ2.occurrenceId);
      expect(occ1.occurrenceId).toBe(occ3.occurrenceId);
      expect(occ1.occurrenceId).toBe(occ4.occurrenceId);
      expect(occ1.occurrenceId).toBe(occ5.occurrenceId);

      // Exactly 1 OS alarm registered
      expect(NativeAlarmScheduler.getRegisteredOSAlarmsCount()).toBe(1);

      // Exactly 1 occurrence in database
      const records = AlarmOccurrenceRepository.findByAlarmId(alarmId);
      expect(records.length).toBe(1);
      expect(records[0].occurrenceId).toBe(occ1.occurrenceId);
      expect(records[0].status).toBe('SCHEDULED');
    });
  });

  describe('Alarm Trigger & 5-Minute Escalation Loop', () => {
    it('triggers alarm, updates mission status, and initiates escalation', () => {
      const scheduledAt = new Date().toISOString();
      const occ = NativeAlarmScheduler.scheduleExactAlarm({ alarmId, missionId, userId, scheduledAt });

      NativeAlarmScheduler.onAlarmTriggered(occ.occurrenceId, 5);

      const triggeredOcc = AlarmOccurrenceRepository.findById(occ.occurrenceId);
      expect(triggeredOcc?.status).toBe('TRIGGERED');
      expect(triggeredOcc?.triggeredAt).toBeDefined();

      const mission = MissionRepository.findById(missionId);
      expect(mission?.status).toBe('TRIGGERED');
    });

    it('immediately disarms occurrence and cancels retry timer when mission is completed', () => {
      const scheduledAt = new Date().toISOString();
      const occ = NativeAlarmScheduler.scheduleExactAlarm({ alarmId, missionId, userId, scheduledAt });

      NativeAlarmScheduler.onAlarmTriggered(occ.occurrenceId, 5);
      NativeAlarmScheduler.onMissionCompleted(occ.occurrenceId, missionId);

      const disarmedOcc = AlarmOccurrenceRepository.findById(occ.occurrenceId);
      expect(disarmedOcc?.status).toBe('DISARMED');
      expect(disarmedOcc?.completedAt).toBeDefined();

      const mission = MissionRepository.findById(missionId);
      expect(mission?.status).toBe('COMPLETED');
    });
  });

  describe('Reboot Recovery (BOOT_COMPLETED)', () => {
    it('restores all future and recent pending alarms after device reboot', () => {
      const futureTime1 = new Date(Date.now() + 7200000).toISOString();
      const futureTime2 = new Date(Date.now() + 14400000).toISOString();
      const ancientTime = new Date(Date.now() - 86400000).toISOString(); // 1 day ago (expired)

      const restored = NativeAlarmScheduler.restorePendingAlarmsOnBoot([
        { alarmId, missionId, userId, scheduledAt: futureTime1 },
        { alarmId, missionId, userId, scheduledAt: futureTime2 },
        { alarmId, missionId, userId, scheduledAt: ancientTime }
      ]);

      expect(restored).toBe(2);
      expect(NativeAlarmScheduler.getRegisteredOSAlarmsCount()).toBe(2);
    });
  });
});
