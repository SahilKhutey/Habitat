// Authoritative Offline Sync Engine & Conflict Resolution Service
import { DatabaseService } from '../../db/connection';
import { MissionsService } from '../missions/missions.controller';
import { ProofsService } from '../proofs/proofs.controller';
import { MeshService } from '../mesh/mesh.controller';

export interface SyncEvent {
  id: string;
  type: 'MISSION_COMPLETED' | 'ALARM_TOGGLED' | 'PREFERENCES_UPDATED';
  idempotencyKey: string;
  timestamp: string;
  payload: any;
}

export class SyncService {
  /**
   * Processes a batch of offline events with clock drift sanitization,
   * LWW conflict resolution, and multi-device alarm disarm broadcast.
   */
  public static async processBatchSync(userId: string, events: SyncEvent[]): Promise<{
    processed: number;
    syncedCount: number;
    failedCount: number;
    results: Array<{ idempotencyKey: string; status: 'SYNCED' | 'ALREADY_SYNCED' | 'FAILED'; details?: any; error?: string }>;
  }> {
    const db = DatabaseService.getDb();
    const results: Array<{ idempotencyKey: string; status: 'SYNCED' | 'ALREADY_SYNCED' | 'FAILED'; details?: any; error?: string }> = [];

    const nowEpoch = Date.now();
    const MAX_CLOCK_DRIFT_MS = 24 * 60 * 60 * 1000; // 24 hours

    for (const event of events) {
      try {
        const payload = event.payload || {};
        const idempotencyKey = event.idempotencyKey || `${event.type}_${Date.now()}`;

        // 1. Clock Drift Sanitization
        if (event.timestamp) {
          const eventEpoch = new Date(event.timestamp).getTime();
          if (isNaN(eventEpoch) || Math.abs(nowEpoch - eventEpoch) > MAX_CLOCK_DRIFT_MS) {
            results.push({
              idempotencyKey,
              status: 'FAILED',
              error: 'CLOCK_DRIFT_REJECTED: Event timestamp exceeds permissible 24-hour window'
            });
            continue;
          }
        }

        // 2. Process Event by Type
        switch (event.type) {
          case 'MISSION_COMPLETED': {
            // Check if already completed with this idempotency key
            const existingMission = db.prepare('SELECT id, status FROM missions WHERE idempotency_key = ?').get(idempotencyKey) as any;

            if (existingMission && existingMission.status === 'COMPLETED') {
              results.push({
                idempotencyKey,
                status: 'ALREADY_SYNCED',
                details: { missionId: existingMission.id }
              });
              continue;
            }

            let validAlarmId: string | null = null;
            if (payload.alarmId) {
              const alarmExists = db.prepare('SELECT id FROM alarms WHERE id = ?').get(payload.alarmId);
              if (alarmExists) validAlarmId = payload.alarmId;
            }

            // Create or fetch mission
            const mission = MissionsService.triggerMission({
              userId,
              alarmId: validAlarmId || undefined,
              taskId: payload.taskId,
              disciplineMode: payload.disciplineMode || 'DISCIPLINE',
              scheduledAt: payload.scheduledAt || event.timestamp,
              idempotencyKey
            });

            // Ingest Proof
            const proofResult = await ProofsService.submitAndVerify({
              missionId: mission!.id,
              mediaType: payload.mediaType || 'image/jpeg',
              storageKey: payload.storageKey || 'offline-sync-proof.jpg',
              capturedAt: payload.capturedAt || event.timestamp || new Date().toISOString(),
              deviceTelemetry: payload.deviceTelemetry || { syncSource: 'OFFLINE_QUEUE' }
            });

            // Disarm other devices in mesh network
            MeshService.dispatchMeshEvent(userId, 'ALARM_DISARM_REMOTE', {
              alarmId: payload.alarmId,
              missionId: mission!.id,
              completedAt: new Date().toISOString()
            });

            results.push({
              idempotencyKey,
              status: 'SYNCED',
              details: { missionId: mission!.id, proofResult }
            });
            break;
          }

          case 'ALARM_TOGGLED': {
            // LWW Conflict Resolution for Alarm is_enabled
            if (payload.alarmId) {
              db.prepare('UPDATE alarms SET is_enabled = ?, updated_at = ? WHERE id = ? AND user_id = ?').run(
                payload.isEnabled ? 1 : 0,
                new Date().toISOString(),
                payload.alarmId,
                userId
              );
              results.push({
                idempotencyKey,
                status: 'SYNCED',
                details: { alarmId: payload.alarmId, isEnabled: payload.isEnabled }
              });
            }
            break;
          }

          case 'PREFERENCES_UPDATED': {
            // LWW Conflict Resolution for User Preferences
            const updates = payload.preferences || {};
            const existingPref = db.prepare('SELECT * FROM user_preferences WHERE user_id = ?').get(userId) as any;

            if (existingPref) {
              db.prepare(`
                UPDATE user_preferences 
                SET theme = COALESCE(?, theme),
                    notifications_enabled = COALESCE(?, notifications_enabled),
                    sound_enabled = COALESCE(?, sound_enabled),
                    vibration_enabled = COALESCE(?, vibration_enabled),
                    updated_at = ?
                WHERE user_id = ?
              `).run(
                updates.theme || null,
                updates.notificationsEnabled !== undefined ? (updates.notificationsEnabled ? 1 : 0) : null,
                updates.soundEnabled !== undefined ? (updates.soundEnabled ? 1 : 0) : null,
                updates.vibrationEnabled !== undefined ? (updates.vibrationEnabled ? 1 : 0) : null,
                new Date().toISOString(),
                userId
              );
            } else {
              db.prepare(`
                INSERT INTO user_preferences (user_id, theme, notifications_enabled, sound_enabled, vibration_enabled, motivational_feedback, reduced_motion, updated_at)
                VALUES (?, ?, ?, ?, ?, 1, ?, ?)
              `).run(
                userId,
                updates.theme || 'system',
                updates.notificationsEnabled !== undefined ? (updates.notificationsEnabled ? 1 : 0) : 1,
                updates.soundEnabled !== undefined ? (updates.soundEnabled ? 1 : 0) : 1,
                updates.vibrationEnabled !== undefined ? (updates.vibrationEnabled ? 1 : 0) : 1,
                updates.reducedMotion !== undefined ? (updates.reducedMotion ? 1 : 0) : 0,
                new Date().toISOString()
              );
            }
            results.push({
              idempotencyKey,
              status: 'SYNCED',
              details: { updated: true }
            });
            break;
          }

          default:
            results.push({
              idempotencyKey,
              status: 'FAILED',
              error: `UNKNOWN_EVENT_TYPE: ${(event as any).type}`
            });
        }
      } catch (err: any) {
        results.push({
          idempotencyKey: event.idempotencyKey || 'unknown',
          status: 'FAILED',
          error: err.message
        });
      }
    }

    const syncedCount = results.filter((r) => r.status === 'SYNCED' || r.status === 'ALREADY_SYNCED').length;
    const failedCount = results.filter((r) => r.status === 'FAILED').length;

    return {
      processed: events.length,
      syncedCount,
      failedCount,
      results
    };
  }
}
