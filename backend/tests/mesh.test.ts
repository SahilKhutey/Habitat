// Integration Tests for V9 Real-Time Multi-Device Wakeup Mesh
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { MeshService } from '../src/modules/mesh/mesh.controller';

describe('V9 Multi-Device Wakeup Mesh: Synchronized Alarms & Disarm Broadcasts', () => {
  let defaultUserId: string;
  let primaryPhoneId: string;
  let tabletId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;
  });

  it('enrolls primary phone, bedside tablet, and smartwatch into user wakeup mesh', () => {
    const phone = MeshService.registerDevice({
      userId: defaultUserId,
      deviceName: 'Pixel 9 Pro (Primary)',
      deviceType: 'PHONE'
    });
    expect(phone).toBeDefined();
    primaryPhoneId = phone.id;

    const tablet = MeshService.registerDevice({
      userId: defaultUserId,
      deviceName: 'iPad Pro (Bedside)',
      deviceType: 'TABLET'
    });
    tabletId = tablet.id;

    const watch = MeshService.registerDevice({
      userId: defaultUserId,
      deviceName: 'Apple Watch Ultra',
      deviceType: 'WATCH'
    });
    expect(watch).toBeDefined();
  });

  it('queries active mesh topology and online node statuses', () => {
    const devices = MeshService.getMeshDevices(defaultUserId);

    expect(devices.length).toBe(3);
    expect(devices.some((d) => d.deviceType === 'PHONE')).toBe(true);
    expect(devices.some((d) => d.deviceType === 'TABLET')).toBe(true);
    expect(devices.every((d) => d.isOnline)).toBe(true);
  });

  it('broadcasts synchronized siren trigger event across all mesh nodes', () => {
    const broadcast = MeshService.broadcastSirenTrigger({
      userId: defaultUserId,
      missionId: 'morning-mission-mesh-01',
      volumeDecibels: 85
    });

    expect(broadcast).toBeDefined();
    expect(broadcast.eventType).toBe('TRIGGER_SIREN');
    expect(broadcast.meshSyncedDevices.length).toBe(3);
    expect(broadcast.volumeDecibels).toBe(85);
  });

  it('broadcasts synchronous disarm message silencing all secondary mesh devices', () => {
    const disarm = MeshService.broadcastDisarm({
      userId: defaultUserId,
      missionId: 'morning-mission-mesh-01',
      verifiedByDevice: 'Pixel 9 Pro (Primary)'
    });

    expect(disarm).toBeDefined();
    expect(disarm.eventType).toBe('DISARM_MESH');
    expect(disarm.verifiedByDevice).toBe('Pixel 9 Pro (Primary)');
    expect(disarm.silencedDevices.length).toBe(3);
  });

  it('updates device heartbeat ping timestamp', () => {
    const ping = MeshService.heartbeat(primaryPhoneId);
    expect(ping.success).toBe(true);
    expect(ping.lastPingAt).toBeDefined();
  });
});
