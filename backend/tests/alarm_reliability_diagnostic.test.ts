// Unit & Integration Tests: Alarm Reliability Diagnostic & "Test My Alarm" Engine
import { describe, it, expect, beforeEach } from 'vitest';
import { AlarmReliabilityService } from '../src/modules/alarms/services/alarm-reliability.service';

describe('AlarmReliabilityService & OEM Diagnostics', () => {
  beforeEach(() => {
    AlarmReliabilityService.resetForTesting();
  });

  describe('OEM Power Management Diagnostics', () => {
    it('diagnoses Samsung device and returns Never Sleeping Apps guidance', () => {
      const result = AlarmReliabilityService.diagnoseDevice({
        platform: 'android',
        osVersion: '14',
        manufacturer: 'Samsung',
        canScheduleExactAlarms: true,
        notificationsEnabled: true,
        isIgnoringBatteryOptimizations: false, // User hasn't disabled optimization yet
        backgroundExecutionRestricted: false
      });

      expect(result.manufacturer).toBe('Samsung');
      expect(result.canScheduleExactAlarms).toBe('CONFIRMED');
      expect(result.notificationsEnabled).toBe('CONFIRMED');
      expect(result.batteryOptimizationStatus).toBe('ACTION_RECOMMENDED');
      expect(result.overallReliability).toBe('NEEDS_ATTENTION');
      expect(result.oemGuidance?.oemName).toBe('Samsung');
      expect(result.oemGuidance?.batterySaverRisk).toBe('HIGH');
      expect(result.oemGuidance?.specificSteps.some((s) => s.includes('Never Sleeping Apps'))).toBe(true);
    });

    it('diagnoses Xiaomi device and returns Autostart & No Restrictions guidance', () => {
      const result = AlarmReliabilityService.diagnoseDevice({
        platform: 'android',
        osVersion: '13',
        manufacturer: 'Xiaomi',
        canScheduleExactAlarms: true,
        notificationsEnabled: true,
        isIgnoringBatteryOptimizations: true,
        backgroundExecutionRestricted: false
      });

      expect(result.manufacturer).toBe('Xiaomi');
      expect(result.overallReliability).toBe('EXCELLENT');
      expect(result.oemGuidance?.oemName).toBe('Xiaomi');
      expect(result.oemGuidance?.specificSteps.some((s) => s.includes('Autostart'))).toBe(true);
    });

    it('diagnoses OnePlus device and flags high battery optimization risk', () => {
      const result = AlarmReliabilityService.diagnoseDevice({
        platform: 'android',
        osVersion: '14',
        manufacturer: 'OnePlus',
        canScheduleExactAlarms: true,
        notificationsEnabled: true,
        isIgnoringBatteryOptimizations: false
      });

      expect(result.oemGuidance?.oemName).toBe('OnePlus');
      expect(result.oemGuidance?.batterySaverRisk).toBe('HIGH');
      expect(result.overallReliability).toBe('NEEDS_ATTENTION');
    });

    it('flags CRITICAL reliability if exact alarm permission is missing', () => {
      const result = AlarmReliabilityService.diagnoseDevice({
        platform: 'android',
        osVersion: '14',
        manufacturer: 'Google',
        canScheduleExactAlarms: false, // Missing SCHEDULE_EXACT_ALARM
        notificationsEnabled: true,
        isIgnoringBatteryOptimizations: true
      });

      expect(result.canScheduleExactAlarms).toBe('ACTION_RECOMMENDED');
      expect(result.overallReliability).toBe('CRITICAL');
    });

    it('diagnoses iOS device with Apple platform defaults', () => {
      const result = AlarmReliabilityService.diagnoseDevice({
        platform: 'ios',
        osVersion: '17.4',
        notificationsEnabled: true
      });

      expect(result.platform).toBe('ios');
      expect(result.canScheduleExactAlarms).toBe('CONFIRMED');
      expect(result.batteryOptimizationStatus).toBe('CONFIRMED');
      expect(result.overallReliability).toBe('EXCELLENT');
    });
  });

  describe('"Test My Alarm" Diagnostic Flow', () => {
    it('creates a test alarm session and confirms physical delivery', () => {
      const session = AlarmReliabilityService.startTestAlarm(60);

      expect(session.testId).toBeDefined();
      expect(session.status).toBe('SCHEDULED');
      expect(new Date(session.fireAt).getTime()).toBeGreaterThan(Date.now());

      const fetched = AlarmReliabilityService.getTestAlarm(session.testId);
      expect(fetched).toBeDefined();
      expect(fetched?.testId).toBe(session.testId);

      // User confirms delivery
      const confirmation = AlarmReliabilityService.confirmTestAlarm(session.testId);
      expect(confirmation.confirmed).toBe(true);
      expect(confirmation.deliveredAt).toBeDefined();

      const confirmedSession = AlarmReliabilityService.getTestAlarm(session.testId);
      expect(confirmedSession?.status).toBe('CONFIRMED');
    });

    it('throws error when confirming invalid or expired test alarm', () => {
      expect(() => AlarmReliabilityService.confirmTestAlarm('invalid_id')).toThrow('TEST_ALARM_NOT_FOUND');
    });
  });
});
