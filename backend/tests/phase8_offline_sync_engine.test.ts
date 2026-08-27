// Phase 8 Offline Sync, Conflict Resolution & Multi-Device Coordination Master Integration Tests
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { AlarmsService } from '../src/modules/alarms/alarms.controller';
import { SyncService } from '../src/modules/sync/sync.service';
import { MeshService } from '../src/modules/mesh/mesh.controller';

describe('Phase 8 Acceptance Gate: Offline Sync, Conflict Resolution & Multi-Device Coordination', () => {
  let userId: string;
  let taskId: string;
  let alarmId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    userId = seeded.defaultUserId;

    // Create a task
    const task = TasksService.createCustomTask(userId, {
      name: 'Cold Water Hydration',
      description: '500ml water immediately after wakeup',
      category: 'HEALTH',
      proofType: 'PHOTO',
      difficulty: 1,
      baseXp: 30
    });
    taskId = task.id;

    // Create an alarm
    const alarm = AlarmsService.create({
      userId,
      taskId,
      timeOfDay: '07:00',
      timezone: 'America/New_York',
      repeatDays: [1, 2, 3, 4, 5],
      disciplineMode: 'DISCIPLINE',
      retryIntervalMinutes: 5
    });
    alarmId = alarm.id;

    // Register 2 mesh devices
    MeshService.registerDevice({ userId, deviceName: 'Pixel 9 Pro (Master)', deviceType: 'ANDROID' });
    MeshService.registerDevice({ userId, deviceName: 'iPad Air (Bedside)', deviceType: 'IOS' });
  });

  it('Gate 1: Batch Ingests offline completed missions atomically', async () => {
    const offlineIdempotencyKey = `offline_sync_${Date.now()}`;
    const nowIso = new Date().toISOString();

    const batchResult = await SyncService.processBatchSync(userId, [
      {
        id: 'sync-event-1',
        type: 'MISSION_COMPLETED',
        idempotencyKey: offlineIdempotencyKey,
        timestamp: nowIso,
        payload: {
          alarmId,
          taskId,
          scheduledAt: nowIso,
          mediaType: 'image/jpeg',
          storageKey: 'offline_proof_01.jpg',
          capturedAt: nowIso,
          deviceTelemetry: { syncSource: 'OFFLINE_CACHE', batteryLevel: 92 }
        }
      }
    ]);

    expect(batchResult.processed).toBe(1);
    expect(batchResult.syncedCount).toBe(1);
    expect(batchResult.failedCount).toBe(0);
    expect(batchResult.results[0].status).toBe('SYNCED');
    expect(batchResult.results[0].details?.missionId).toBeDefined();

    // Verify Mission is COMPLETED in Database
    const db = DatabaseService.getDb();
    const mission = db.prepare('SELECT status, completed_at FROM missions WHERE idempotency_key = ?').get(offlineIdempotencyKey) as any;
    expect(mission?.status).toBe('COMPLETED');
    expect(mission?.completed_at).toBeDefined();
  });

  it('Gate 2: Idempotent Replay: Re-sending identical offline payload returns ALREADY_SYNCED without double completion', async () => {
    const offlineIdempotencyKey = `offline_replay_test_${Date.now()}`;
    const nowIso = new Date().toISOString();

    const initialSync = await SyncService.processBatchSync(userId, [
      {
        id: 'sync-event-replay',
        type: 'MISSION_COMPLETED',
        idempotencyKey: offlineIdempotencyKey,
        timestamp: nowIso,
        payload: {
          alarmId,
          taskId,
          scheduledAt: nowIso,
          mediaType: 'image/jpeg',
          storageKey: 'offline_proof_replay.jpg',
          capturedAt: nowIso
        }
      }
    ]);
    expect(initialSync.results[0].status).toBe('SYNCED');

    // Replay with exact same idempotencyKey
    const replaySync = await SyncService.processBatchSync(userId, [
      {
        id: 'sync-event-replay',
        type: 'MISSION_COMPLETED',
        idempotencyKey: offlineIdempotencyKey,
        timestamp: nowIso,
        payload: {
          alarmId,
          taskId,
          scheduledAt: nowIso,
          mediaType: 'image/jpeg',
          storageKey: 'offline_proof_replay.jpg',
          capturedAt: nowIso
        }
      }
    ]);

    expect(replaySync.syncedCount).toBe(1);
    expect(replaySync.results[0].status).toBe('ALREADY_SYNCED');
    expect(replaySync.results[0].details?.missionId).toBe(initialSync.results[0].details?.missionId);
  });

  it('Gate 3: Clock Drift Sanitizer: Rejects events with timestamps outside the 24-hour window', async () => {
    // 3 days in future (clock manipulation attempt)
    const futureTimestamp = new Date(Date.now() + 72 * 60 * 60 * 1000).toISOString();

    const result = await SyncService.processBatchSync(userId, [
      {
        id: 'sync-tampered',
        type: 'MISSION_COMPLETED',
        idempotencyKey: 'tampered-key-01',
        timestamp: futureTimestamp,
        payload: {
          taskId,
          scheduledAt: futureTimestamp
        }
      }
    ]);

    expect(result.failedCount).toBe(1);
    expect(result.results[0].status).toBe('FAILED');
    expect(result.results[0].error).toContain('CLOCK_DRIFT_REJECTED');
  });

  it('Gate 4: LWW Conflict Resolution on Alarm Schedule State Changes', async () => {
    const syncResult = await SyncService.processBatchSync(userId, [
      {
        id: 'sync-alarm-toggle',
        type: 'ALARM_TOGGLED',
        idempotencyKey: `alarm_toggle_${Date.now()}`,
        timestamp: new Date().toISOString(),
        payload: {
          alarmId,
          isEnabled: false
        }
      }
    ]);

    expect(syncResult.syncedCount).toBe(1);

    // Verify DB updated
    const db = DatabaseService.getDb();
    const alarmRow = db.prepare('SELECT is_enabled FROM alarms WHERE id = ?').get(alarmId) as any;
    expect(alarmRow.is_enabled).toBe(0);
  });

  it('Gate 5: LWW Conflict Resolution on User Preferences', async () => {
    const syncResult = await SyncService.processBatchSync(userId, [
      {
        id: 'sync-pref-update',
        type: 'PREFERENCES_UPDATED',
        idempotencyKey: `pref_update_${Date.now()}`,
        timestamp: new Date().toISOString(),
        payload: {
          preferences: {
            theme: 'dark',
            soundEnabled: true,
            reducedMotion: false
          }
        }
      }
    ]);

    expect(syncResult.syncedCount).toBe(1);

    const db = DatabaseService.getDb();
    const prefRow = db.prepare('SELECT theme FROM user_preferences WHERE user_id = ?').get(userId) as any;
    expect(prefRow.theme).toBe('dark');
  });

  it('Gate 6: Multi-Device Alarm Disarm Mesh Broadcast on Sync', async () => {
    const syncKey = `disarm_mesh_test_${Date.now()}`;
    const nowIso = new Date().toISOString();

    await SyncService.processBatchSync(userId, [
      {
        id: 'sync-mesh-disarm',
        type: 'MISSION_COMPLETED',
        idempotencyKey: syncKey,
        timestamp: nowIso,
        payload: {
          alarmId,
          taskId,
          scheduledAt: nowIso
        }
      }
    ]);

    // Check mesh events table for ALARM_DISARM_REMOTE
    const db = DatabaseService.getDb();
    const meshEvents = db.prepare("SELECT * FROM mesh_events WHERE user_id = ? AND event_type = 'ALARM_DISARM_REMOTE'").all(userId) as any[];
    expect(meshEvents.length).toBeGreaterThanOrEqual(1);

    const lastEvent = meshEvents[meshEvents.length - 1];
    const payload = JSON.parse(lastEvent.payload);
    expect(payload.alarmId).toBe(alarmId);
    expect(payload.completedAt).toBeDefined();
  });
});
