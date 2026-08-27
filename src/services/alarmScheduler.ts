// Alarm Scheduler Daemon (Background Trigger Loop)
import { AlarmRepository } from '../db/repositories/alarmRepository';
import { MissionRepository } from '../db/repositories/missionRepository';
import { MissionService } from './missionService';

export class AlarmScheduler {
  private static interval: NodeJS.Timeout | null = null;
  private static isRunning: boolean = false;

  public static start(checkIntervalMs: number = 30000): void {
    if (this.isRunning) return;
    this.isRunning = true;

    console.log(`[SCHEDULER] Alarm Scheduler Daemon active (polling every ${checkIntervalMs / 1000}s)`);

    this.interval = setInterval(async () => {
      await this.checkAndTriggerAlarms();
    }, checkIntervalMs);

    // Initial immediate check
    this.checkAndTriggerAlarms();
  }

  public static stop(): void {
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = null;
    }
    this.isRunning = false;
    console.log('[SCHEDULER] Alarm Scheduler Daemon stopped.');
  }

  public static async checkAndTriggerAlarms(): Promise<void> {
    try {
      const now = new Date();
      const currentDay = now.getDay(); // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
      const currentTimeStr = now.toTimeString().substring(0, 5); // "HH:MM"
      const todayDateStr = now.toISOString().substring(0, 10); // "YYYY-MM-DD"

      const activeAlarms = AlarmRepository.getActiveAlarms();

      for (const alarm of activeAlarms) {
        // Check if today is a repeat day
        if (!alarm.repeatDays.includes(currentDay)) {
          continue;
        }

        // Check if alarm time matches current HH:MM
        const alarmHHMM = alarm.timeOfDay.substring(0, 5);
        if (alarmHHMM === currentTimeStr) {
          // Verify we haven't already spawned a mission for this alarm today
          const todaysMissions = MissionRepository.getTodaysMissions(alarm.userId, todayDateStr);
          const alreadySpawned = todaysMissions.some((m) => m.alarmId === alarm.id);

          if (!alreadySpawned) {
            console.log(`[SCHEDULER] Triggering scheduled alarm ${alarm.id} for user ${alarm.userId}`);
            await MissionService.triggerMission({
              userId: alarm.userId,
              alarmId: alarm.id,
              taskId: alarm.taskId,
              disciplineMode: alarm.disciplineMode,
              scheduledFor: `${todayDateStr}T${alarm.timeOfDay}Z`
            });
          }
        }
      }
    } catch (e) {
      console.error('[SCHEDULER] Error during alarm evaluation:', e);
    }
  }
}
