// Integration Tests for V8 Iron Fortress App Lockdown & Discipline Bonds
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { LockdownService } from '../src/modules/lockdown/lockdown.controller';
import { GamificationService } from '../src/modules/gamification/gamification.controller';

describe('V8 Iron Fortress: App Quarantine, Discipline Bonds & Emergency Bypass', () => {
  let defaultUserId: string;
  let bondId1: string;
  let bondId2: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;
  });

  it('retrieves default lockdown quarantine settings and blocked packages', () => {
    const settings = LockdownService.getSettings(defaultUserId);

    expect(settings).toBeDefined();
    expect(settings.isShieldEnabled).toBe(true);
    expect(settings.blockedApps.length).toBeGreaterThanOrEqual(4);
    expect(settings.quarantineDurationMinutes).toBe(60);
  });

  it('updates blocked apps and enables strict mode', () => {
    const updated = LockdownService.updateSettings({
      userId: defaultUserId,
      blockedApps: ['com.instagram.android', 'com.zhiliaoapp.musically', 'com.netflix.mediaclient'],
      quarantineDurationMinutes: 45,
      strictMode: true
    });

    expect(updated.blockedApps.length).toBe(3);
    expect(updated.quarantineDurationMinutes).toBe(45);
    expect(updated.strictMode).toBe(true);
  });

  it('stakes an XP discipline bond on tomorrow morning wakeup', () => {
    const bond = LockdownService.stakeBond({
      userId: defaultUserId,
      stakedXp: 200
    });

    expect(bond).toBeDefined();
    expect(bond.stakedXp).toBe(200);
    expect(bond.status).toBe('ACTIVE');

    bondId1 = bond.bondId;

    // Second bond for forfeiture test
    const bond2 = LockdownService.stakeBond({
      userId: defaultUserId,
      stakedXp: 100
    });
    bondId2 = bond2.bondId;
  });

  it('settles honored bond with +50% speed bonus deposited in XP ledger', () => {
    const initialLedger = GamificationService.getLedger(defaultUserId);
    const initialXp = initialLedger.totalXp;

    const settled = LockdownService.settleBond({
      bondId: bondId1,
      isHonored: true,
      instantBonus: true
    });

    expect(settled.status).toBe('HONORED');

    const updatedLedger = GamificationService.getLedger(defaultUserId);
    expect(updatedLedger.totalXp).toBe(initialXp + 300); // 200 + 50% = +300 XP
  });

  it('settles forfeited bond by penalizing ledger balance', () => {
    const initialLedger = GamificationService.getLedger(defaultUserId);
    const initialXp = initialLedger.totalXp;

    const settled = LockdownService.settleBond({
      bondId: bondId2,
      isHonored: false
    });

    expect(settled.status).toBe('FORFEITED');

    const updatedLedger = GamificationService.getLedger(defaultUserId);
    expect(updatedLedger.totalXp).toBe(initialXp - 100); // -100 XP penalty
  });

  it('authorizes emergency bypass and logs audited reason', () => {
    const bypass = LockdownService.requestEmergencyBypass({
      userId: defaultUserId,
      reason: 'Urgent family medical communication'
    });

    expect(bypass).toBeDefined();
    expect(bypass.authorized).toBe(true);
    expect(bypass.unlockMinutes).toBe(15);
    expect(bypass.reason).toBe('Urgent family medical communication');
  });
});
