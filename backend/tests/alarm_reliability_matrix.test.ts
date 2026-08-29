// Automated Test Suite for Milestone C1: Alarm Reliability Matrix & OEM Profile Evaluation
import { describe, it, expect } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';

describe('Milestone C1: Real-Device Alarm Reliability Matrix & Diagnostics', () => {
  const reportPath = path.resolve(__dirname, '../../docs/testing/alarm-reliability.md');

  it('C1.1: Verification report docs/testing/alarm-reliability.md exists and contains empirical matrix', () => {
    expect(fs.existsSync(reportPath)).toBe(true);
    const content = fs.readFileSync(reportPath, 'utf-8');

    expect(content).toContain('Empirical Real-Device Reliability Matrix');
    expect(content).toContain('Google Pixel 8 Pro');
    expect(content).toContain('Samsung Galaxy S23');
    expect(content).toContain('Xiaomi 13 Pro');
    expect(content).toContain('Apple iPhone 15 Pro');
  });

  it('C1.2: Evaluates Doze mode and App Standby piercing requirements', () => {
    const content = fs.readFileSync(reportPath, 'utf-8');

    expect(content).toContain('dumpsys deviceidle force-idle');
    expect(content).toContain('am set-standby-bucket');
    expect(content).toContain('setExactAndAllowWhileIdle');
  });

  it('C1.3: Evaluates OEM-specific power management constraints for Samsung and Xiaomi', () => {
    const content = fs.readFileSync(reportPath, 'utf-8');

    expect(content).toContain('Never sleeping apps');
    expect(content).toContain('Autostart');
    expect(content).toContain('No restrictions');
    expect(content).toContain('Appear on top');
  });

  it('C1.4: Formulates stopSirenAudio failure mode and decoupled termination invariant', () => {
    const content = fs.readFileSync(reportPath, 'utf-8');

    expect(content).toContain('stopSirenAudio()');
    expect(content).toContain('ACTION_DISMISS_ALARM');
    expect(content).toContain('WakeLock');
  });

  it('C1.5: Verifies iOS SpringBoard notification execution vs MethodChannel audio bounds', () => {
    const content = fs.readFileSync(reportPath, 'utf-8');

    expect(content).toContain('Force-Quit');
    expect(content).toContain('UserNotifications.framework');
    expect(content).toContain('defaultCriticalSound');
  });
});
