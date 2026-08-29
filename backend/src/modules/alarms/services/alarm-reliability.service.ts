// Alarm Reliability Service & OEM Diagnostic Engine
import { v4 as uuidv4 } from 'uuid';
import {
  AlarmHealth,
  DeviceDiagnosticInput,
  DiagnosticStatus,
  OEMGuidance,
  OEMVendor,
  TestAlarmSession
} from '../domain/alarm-health.types';

export class AlarmReliabilityService {
  private static activeTestAlarms = new Map<string, TestAlarmSession>();

  /**
   * Evaluates device health parameters and constructs actionable OEM guidance
   */
  public static diagnoseDevice(input: DeviceDiagnosticInput): AlarmHealth {
    const oem = this.identifyOEM(input.manufacturer || '', input.platform);
    const oemGuidance = this.getOEMGuidance(oem);

    const exactAlarmStatus: DiagnosticStatus = input.platform === 'ios'
      ? 'CONFIRMED'
      : (input.canScheduleExactAlarms === true ? 'CONFIRMED' : (input.canScheduleExactAlarms === false ? 'ACTION_RECOMMENDED' : 'CANNOT_VERIFY'));

    const notificationsStatus: DiagnosticStatus = input.notificationsEnabled === true
      ? 'CONFIRMED'
      : (input.notificationsEnabled === false ? 'ACTION_RECOMMENDED' : 'CANNOT_VERIFY');

    const batteryOptStatus: DiagnosticStatus = input.platform === 'ios'
      ? 'CONFIRMED'
      : (input.isIgnoringBatteryOptimizations === true ? 'CONFIRMED' : 'ACTION_RECOMMENDED');

    const bgStatus: DiagnosticStatus = input.backgroundExecutionRestricted === true
      ? 'ACTION_RECOMMENDED'
      : 'CONFIRMED';

    // Calculate Overall Reliability Tier
    let overallReliability: AlarmHealth['overallReliability'] = 'EXCELLENT';
    if (exactAlarmStatus === 'ACTION_RECOMMENDED' || notificationsStatus === 'ACTION_RECOMMENDED') {
      overallReliability = 'CRITICAL';
    } else if (batteryOptStatus === 'ACTION_RECOMMENDED' || bgStatus === 'ACTION_RECOMMENDED') {
      overallReliability = oemGuidance.batterySaverRisk === 'HIGH' ? 'NEEDS_ATTENTION' : 'GOOD';
    }

    return {
      canScheduleExactAlarms: exactAlarmStatus,
      notificationsEnabled: notificationsStatus,
      batteryOptimizationStatus: batteryOptStatus,
      backgroundExecution: bgStatus,
      platform: input.platform,
      osVersion: input.osVersion,
      manufacturer: input.manufacturer || (input.platform === 'ios' ? 'Apple' : 'Unknown'),
      overallReliability,
      oemGuidance
    };
  }

  /**
   * Initiates a 1-to-2 minute "Test My Alarm" diagnostic session
   */
  public static startTestAlarm(delaySeconds: number = 60): TestAlarmSession {
    const testId = `test_alm_${uuidv4().substring(0, 8)}`;
    const now = Date.now();
    const fireAt = new Date(now + delaySeconds * 1000).toISOString();
    const expiresAt = new Date(now + (delaySeconds + 300) * 1000).toISOString();

    const session: TestAlarmSession = {
      testId,
      scheduledAt: new Date(now).toISOString(),
      fireAt,
      status: 'SCHEDULED',
      expiresAt
    };

    this.activeTestAlarms.set(testId, session);
    return session;
  }

  /**
   * Confirms successful delivery and dismissal of the test alarm by the user
   */
  public static confirmTestAlarm(testId: string): { confirmed: boolean; testId: string; deliveredAt: string } {
    const session = this.activeTestAlarms.get(testId);
    if (!session) {
      throw new Error('TEST_ALARM_NOT_FOUND: Test alarm session expired or not found');
    }

    const now = new Date().toISOString();
    session.status = 'CONFIRMED';

    return {
      confirmed: true,
      testId,
      deliveredAt: now
    };
  }

  public static getTestAlarm(testId: string): TestAlarmSession | undefined {
    return this.activeTestAlarms.get(testId);
  }

  public static resetForTesting(): void {
    this.activeTestAlarms.clear();
  }

  private static identifyOEM(manufacturer: string, platform: string): OEMVendor {
    if (platform === 'ios') return 'Other';
    const m = manufacturer.toLowerCase();
    if (m.includes('samsung')) return 'Samsung';
    if (m.includes('xiaomi') || m.includes('redmi') || m.includes('poco')) return 'Xiaomi';
    if (m.includes('oneplus')) return 'OnePlus';
    if (m.includes('oppo')) return 'Oppo';
    if (m.includes('vivo') || m.includes('iqoo')) return 'Vivo';
    if (m.includes('realme')) return 'Realme';
    if (m.includes('google') || m.includes('pixel') || m.includes('motorola')) return 'Stock/Pixel';
    return 'Other';
  }

  private static getOEMGuidance(oem: OEMVendor): OEMGuidance {
    switch (oem) {
      case 'Samsung':
        return {
          oemName: 'Samsung',
          batterySaverRisk: 'HIGH',
          specificSteps: [
            'Go to Settings > Battery and Device Care > Battery > Background Usage Limits.',
            'Add Habitat to "Never Sleeping Apps".',
            'Ensure "Put unused apps to sleep" does not target Habitat.'
          ],
          settingsIntentAction: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS'
        };
      case 'Xiaomi':
        return {
          oemName: 'Xiaomi',
          batterySaverRisk: 'HIGH',
          specificSteps: [
            'Go to Settings > Apps > Manage Apps > Habitat.',
            'Enable "Autostart".',
            'Under "Battery Saver", select "No Restrictions".'
          ],
          settingsIntentAction: 'miui.intent.action.OP_AUTO_START'
        };
      case 'OnePlus':
        return {
          oemName: 'OnePlus',
          batterySaverRisk: 'HIGH',
          specificSteps: [
            'Go to Settings > Battery > Battery Optimization > Habitat.',
            'Select "Don\'t Optimize".',
            'Disable "Sleep Standby Optimization" under Advanced Battery Settings.'
          ],
          settingsIntentAction: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS'
        };
      case 'Oppo':
      case 'Realme':
        return {
          oemName: oem,
          batterySaverRisk: 'HIGH',
          specificSteps: [
            'Go to Settings > Battery > App Battery Management > Habitat.',
            'Enable "Allow background activity" and "Allow auto-launch".'
          ],
          settingsIntentAction: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS'
        };
      case 'Vivo':
        return {
          oemName: 'Vivo',
          batterySaverRisk: 'HIGH',
          specificSteps: [
            'Go to Settings > Battery > High Background Power Consumption.',
            'Toggle ON Habitat to prevent foreground service termination.'
          ],
          settingsIntentAction: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS'
        };
      case 'Stock/Pixel':
      default:
        return {
          oemName: oem,
          batterySaverRisk: 'LOW',
          specificSteps: [
            'Go to Settings > Apps > Habitat > Battery.',
            'Select "Unrestricted".'
          ],
          settingsIntentAction: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS'
        };
    }
  }
}
