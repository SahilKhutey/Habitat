// Idempotent Native Alarm Scheduler & 5-Minute Escalation Retry Engine
import { AlarmOccurrenceRepository } from '../../../repositories/alarm-occurrence.repository';
import { MissionRepository } from '../../../repositories/mission.repository';
import { AlarmOccurrence } from '../domain/alarm-occurrence.types';

export interface ScheduleRequest {
  alarmId: string;
  missionId: string;
  userId: string;
  scheduledAt: string;
  platform?: 'android' | 'ios' | 'web';
  retryIntervalMinutes?: number;
}

export class NativeAlarmScheduler {
  // In-memory active OS alarm registry representing OS scheduler state (AlarmManager / UNNotification)
  private static registeredOSAlarms = new Map<string, {
    occurrenceId: string;
    scheduledAt: string;
    cancelled: boolean;
  }>();

  private static activeRetryTimers = new Map<string, NodeJS.Timeout>();

  /**
   * Schedules an exact alarm idempotently. Multiple invocations with the same (alarmId, scheduledAt)
   * never create duplicate OS alarms or duplicate occurrence records.
   */
  public static scheduleExactAlarm(request: ScheduleRequest): AlarmOccurrence {
    const timestampMs = new Date(request.scheduledAt).getTime();
    const occurrenceId = `occ_${request.alarmId}_${timestampMs}`;

    // 1. Check if already registered in OS Scheduler
    const existing = this.registeredOSAlarms.get(occurrenceId);
    if (existing && !existing.cancelled) {
      const existingRecord = AlarmOccurrenceRepository.findById(occurrenceId);
      if (existingRecord) {
        return existingRecord;
      }
    }

    // 2. Register with OS Scheduler
    this.registeredOSAlarms.set(occurrenceId, {
      occurrenceId,
      scheduledAt: request.scheduledAt,
      cancelled: false
    });

    // 3. Persist occurrence record in local DB
    const existingDb = AlarmOccurrenceRepository.findById(occurrenceId);
    if (existingDb) {
      return existingDb;
    }

    return AlarmOccurrenceRepository.create({
      occurrenceId,
      alarmId: request.alarmId,
      missionId: request.missionId,
      userId: request.userId,
      scheduledAt: request.scheduledAt,
      platform: request.platform || 'android'
    });
  }

  /**
   * Called by Native OS Receiver (AlarmManager or UNNotification) when the alarm fires
   */
  public static onAlarmTriggered(occurrenceId: string, retryIntervalMinutes: number = 5): void {
    const occurrence = AlarmOccurrenceRepository.findById(occurrenceId);
    if (!occurrence) return;

    AlarmOccurrenceRepository.markTriggered(occurrenceId);
    MissionRepository.updateStatus(occurrence.missionId, 'TRIGGERED');

    // Start 5-minute escalation retry timer in case the user ignores the mission
    this.scheduleEscalationRetry(occurrenceId, retryIntervalMinutes);
  }

  /**
   * Schedules an idempotent 5-minute retry if task is not completed
   */
  public static scheduleEscalationRetry(occurrenceId: string, retryIntervalMinutes: number = 5): void {
    this.cancelRetryTimer(occurrenceId);

    const timer = setTimeout(() => {
      const occurrence = AlarmOccurrenceRepository.findById(occurrenceId);
      if (occurrence && occurrence.status !== 'DISARMED') {
        AlarmOccurrenceRepository.incrementRetry(occurrenceId);
        MissionRepository.updateStatus(occurrence.missionId, 'TRIGGERED');
        // Continue escalation cycle
        this.scheduleEscalationRetry(occurrenceId, retryIntervalMinutes);
      }
    }, retryIntervalMinutes * 60 * 1000);

    // Unref timer in Node so it doesn't hang process termination in test runners
    if (timer.unref) timer.unref();

    this.activeRetryTimers.set(occurrenceId, timer);
  }

  /**
   * Immediately cancels any pending retry timers and marks occurrence disarmed
   */
  public static onMissionCompleted(occurrenceId: string, missionId: string): void {
    this.cancelRetryTimer(occurrenceId);
    AlarmOccurrenceRepository.markDisarmed(occurrenceId);
    MissionRepository.updateStatus(missionId, 'COMPLETED', new Date().toISOString());
  }

  /**
   * Re-registers pending scheduled alarms upon device reboot (BOOT_COMPLETED)
   */
  public static restorePendingAlarmsOnBoot(pendingAlarms: Array<{
    alarmId: string;
    missionId: string;
    userId: string;
    scheduledAt: string;
    platform?: 'android' | 'ios';
  }>): number {
    let restoredCount = 0;
    const now = Date.now();

    for (const alarm of pendingAlarms) {
      const scheduledTime = new Date(alarm.scheduledAt).getTime();
      // Restore if scheduled time is in the future or within the 10-minute grace window
      if (scheduledTime >= now - 10 * 60 * 1000) {
        this.scheduleExactAlarm({
          alarmId: alarm.alarmId,
          missionId: alarm.missionId,
          userId: alarm.userId,
          scheduledAt: alarm.scheduledAt,
          platform: alarm.platform || 'android'
        });
        restoredCount++;
      }
    }

    return restoredCount;
  }

  public static cancelAlarm(occurrenceId: string): void {
    this.cancelRetryTimer(occurrenceId);
    const osAlarm = this.registeredOSAlarms.get(occurrenceId);
    if (osAlarm) {
      osAlarm.cancelled = true;
    }
  }

  public static cancelNativeAlarm(alarmId: string): void {
    for (const [key, value] of this.registeredOSAlarms.entries()) {
      if (key.includes(alarmId)) {
        this.cancelAlarm(key);
      }
    }
  }

  public static getRegisteredOSAlarmsCount(): number {
    let count = 0;
    for (const item of this.registeredOSAlarms.values()) {
      if (!item.cancelled) count++;
    }
    return count;
  }

  public static resetForTesting(): void {
    for (const timer of this.activeRetryTimers.values()) {
      clearTimeout(timer);
    }
    this.activeRetryTimers.clear();
    this.registeredOSAlarms.clear();
  }

  private static cancelRetryTimer(occurrenceId: string): void {
    const timer = this.activeRetryTimers.get(occurrenceId);
    if (timer) {
      clearTimeout(timer);
      this.activeRetryTimers.delete(occurrenceId);
    }
  }
}
