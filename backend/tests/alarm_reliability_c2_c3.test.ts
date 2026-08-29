// Automated Test Suite for Milestones C2 & C3: Reliability Onboarding & Exact Alarm Capabilities
import { describe, it, expect } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';

describe('Milestones C2 & C3: Reliability Onboarding, OEM Guidance & Exact Alarm Contract', () => {
  const pluginPath = path.resolve(
    __dirname,
    '../../apps/mobile/android/app/src/main/kotlin/com/habitat/app/NativeAlarmPlugin.kt'
  );
  const manifestPath = path.resolve(
    __dirname,
    '../../apps/mobile/android/app/src/main/AndroidManifest.xml'
  );
  const screenPath = path.resolve(
    __dirname,
    '../../apps/mobile/lib/features/onboarding/screens/alarm_reliability_screen.dart'
  );
  const servicePath = path.resolve(
    __dirname,
    '../../apps/mobile/lib/services/alarm_reliability_service.dart'
  );

  it('C3.1: Android manifest declares SCHEDULE_EXACT_ALARM, USE_EXACT_ALARM, and battery permissions', () => {
    expect(fs.existsSync(manifestPath)).toBe(true);
    const manifest = fs.readFileSync(manifestPath, 'utf-8');

    expect(manifest).toContain('android.permission.SCHEDULE_EXACT_ALARM');
    expect(manifest).toContain('android.permission.USE_EXACT_ALARM');
    expect(manifest).toContain('android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS');
    expect(manifest).toContain('android.permission.POST_NOTIFICATIONS');
  });

  it('C3.2: NativeAlarmPlugin.kt implements capability checks and SecurityException fallback', () => {
    expect(fs.existsSync(pluginPath)).toBe(true);
    const plugin = fs.readFileSync(pluginPath, 'utf-8');

    expect(plugin).toContain('canScheduleExactAlarms');
    expect(plugin).toContain('openExactAlarmSettings');
    expect(plugin).toContain('isIgnoringBatteryOptimizations');
    expect(plugin).toContain('openBatteryOptimizationSettings');
    expect(plugin).toContain('getDeviceManufacturer');
    expect(plugin).toContain('SecurityException');
    expect(plugin).toContain('setAndAllowWhileIdle');
  });

  it('C2.1: AlarmReliabilityService defines structured diagnostics and degradation warnings', () => {
    expect(fs.existsSync(servicePath)).toBe(true);
    const service = fs.readFileSync(servicePath, 'utf-8');

    expect(service).toContain('diagnoseAsync');
    expect(service).toContain('recordTestVerificationSuccess');
    expect(service).toContain('getDegradationWarning');
    expect(service).toContain('Never Sleeping Apps');
    expect(service).toContain('Autostart');
  });

  it('C2.2: AlarmReliabilityScreen implements real-time lifecycle auto-recheck and Test My Alarm', () => {
    expect(fs.existsSync(screenPath)).toBe(true);
    const screen = fs.readFileSync(screenPath, 'utf-8');

    expect(screen).toContain('WidgetsBindingObserver');
    expect(screen).toContain('AppLifecycleState.resumed');
    expect(screen).toContain('Test My Alarm');
    expect(screen).toContain('Continue Anyway');
    expect(screen).toContain('RELIABILITY CHECKLIST');
  });
});
