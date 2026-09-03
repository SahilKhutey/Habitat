// Production Alarm Service with lifecycle, reconciliation, and mission triggering
import {
  IAlarmRepository,
  AlarmEntity,
  CreateAlarmInput
} from '../../../repositories/alarm.repository';
import { DatabaseFactory } from '../../../db/database.factory';
import { MissionService } from '../../missions/domain/mission.service';
import { NativeAlarmScheduler } from '../services/native-alarm-scheduler';

export interface ReconciliationContext {
  deviceBootTime?: string;
  currentTimezone?: string;
  batteryExemptionVerified?: boolean;
}

export class AlarmService {
  private readonly missionService: MissionService;

  constructor(
    private readonly repository?: IAlarmRepository,
    missionService?: MissionService
  ) {
    this.missionService = missionService || new MissionService();
  }

  private getRepo(): IAlarmRepository {
    if (this.repository) return this.repository;
    return DatabaseFactory.getAlarmRepository();
  }

  private calculateNextOccurrence(timeOfDay: string): string {
    const now = new Date();
    const [hours, minutes] = timeOfDay.split(':').map(Number);
    const scheduledDate = new Date(now);
    scheduledDate.setHours(hours || 0, minutes || 0, 0, 0);
    if (scheduledDate.getTime() <= now.getTime()) {
      scheduledDate.setDate(scheduledDate.getDate() + 1);
    }
    return scheduledDate.toISOString();
  }

  public async schedule(input: CreateAlarmInput): Promise<AlarmEntity> {
    if (!input.userId || !input.taskId || !input.timeOfDay) {
      throw new Error('INVALID_ALARM: userId, taskId, and timeOfDay are required.');
    }

    const alarm = await this.getRepo().create(input);

    // Schedule native OS wake lock & alarm trigger
    const scheduledAt = this.calculateNextOccurrence(alarm.timeOfDay);
    NativeAlarmScheduler.scheduleExactAlarm({
      alarmId: alarm.id,
      missionId: `mission_${alarm.id}_${Date.now()}`,
      userId: alarm.userId,
      scheduledAt,
      platform: 'android'
    });

    return alarm;
  }

  public async cancel(alarmId: string): Promise<boolean> {
    const alarm = await this.getRepo().findById(alarmId);
    if (!alarm) throw new Error(`ALARM_NOT_FOUND: Alarm ${alarmId} does not exist.`);

    NativeAlarmScheduler.cancelNativeAlarm(alarmId);
    return this.getRepo().delete(alarmId);
  }

  public async reschedule(alarmId: string, newTime: string): Promise<AlarmEntity | null> {
    const alarm = await this.getRepo().findById(alarmId);
    if (!alarm) throw new Error(`ALARM_NOT_FOUND: Alarm ${alarmId} does not exist.`);

    const updated = await this.getRepo().update(alarmId, { timeOfDay: newTime });
    if (updated) {
      const scheduledAt = this.calculateNextOccurrence(updated.timeOfDay);
      NativeAlarmScheduler.scheduleExactAlarm({
        alarmId: updated.id,
        missionId: `mission_${updated.id}_${Date.now()}`,
        userId: updated.userId,
        scheduledAt,
        platform: 'android'
      });
    }
    return updated;
  }

  public async snooze(alarmId: string, minutes: number = 5): Promise<AlarmEntity | null> {
    const alarm = await this.getRepo().findById(alarmId);
    if (!alarm) throw new Error(`ALARM_NOT_FOUND: Alarm ${alarmId} does not exist.`);

    const now = new Date();
    now.setMinutes(now.getMinutes() + minutes);
    const hours = String(now.getHours()).padStart(2, '0');
    const mins = String(now.getMinutes()).padStart(2, '0');
    const snoozeTime = `${hours}:${mins}:00`;

    return this.reschedule(alarmId, snoozeTime);
  }

  /**
   * Triggers an alarm by creating an active mission in the ledger
   */
  public async trigger(alarmId: string): Promise<any> {
    const alarm = await this.getRepo().findById(alarmId);
    if (!alarm) throw new Error(`ALARM_NOT_FOUND: Alarm ${alarmId} does not exist.`);

    const mission = await this.missionService.createMission({
      userId: alarm.userId,
      taskId: alarm.taskId,
      alarmId: alarm.id,
      disciplineMode: alarm.disciplineMode
    });

    // Advance mission directly to TRIGGERED/ACTIVE
    await this.missionService.startMission(mission.id);

    return mission;
  }

  /**
   * Recovers state after app restart, power loss, or OS reboot
   */
  public async reconcile(userId: string, context?: ReconciliationContext): Promise<{
    enabledAlarms: AlarmEntity[];
    reconciledCount: number;
    timezoneAdjusted: boolean;
  }> {
    const alarms = await this.getRepo().findEnabled(userId);
    let reconciledCount = 0;
    let timezoneAdjusted = false;

    for (const alarm of alarms) {
      if (context?.currentTimezone && alarm.timezone !== context.currentTimezone) {
        await this.getRepo().update(alarm.id, { timezone: context.currentTimezone });
        timezoneAdjusted = true;
      }

      // Re-register with native OS AlarmManager
      const scheduledAt = this.calculateNextOccurrence(alarm.timeOfDay);
      NativeAlarmScheduler.scheduleExactAlarm({
        alarmId: alarm.id,
        missionId: `mission_${alarm.id}_${Date.now()}`,
        userId: alarm.userId,
        scheduledAt,
        platform: 'android'
      });
      reconciledCount++;
    }

    return {
      enabledAlarms: alarms,
      reconciledCount,
      timezoneAdjusted
    };
  }

  public async getUserAlarms(userId: string): Promise<AlarmEntity[]> {
    return this.getRepo().findByUserId(userId);
  }

  public async getAlarm(alarmId: string): Promise<AlarmEntity | null> {
    return this.getRepo().findById(alarmId);
  }
}
