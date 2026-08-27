// Health Provider Abstraction & Data Synchronization Service
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { ExerciseService } from './exercise.service';
import { HydrationService } from './hydration.service';
import { SleepService } from './sleep.service';

export interface ActivityImportPayload {
  externalId: string;
  type: string; // e.g. "WALK", "RUN", "PUSHUPS"
  startedAt: string;
  endedAt?: string;
  durationSec: number;
  quantity?: number;
  unit?: string;
}

export interface SleepImportPayload {
  externalId: string;
  startedAt: string;
  endedAt: string;
  quality?: number;
}

export interface HydrationImportPayload {
  externalId: string;
  amountMl: number;
  timestamp: string;
}

export interface HealthSyncBatch {
  userId: string;
  provider: 'APPLE_HEALTH' | 'HEALTH_CONNECT' | 'MANUAL';
  activities?: ActivityImportPayload[];
  sleep?: SleepImportPayload[];
  hydration?: HydrationImportPayload[];
}

export class HealthSyncService {
  /**
   * Synchronizes incoming normalized provider data with strict deduplication
   */
  public static syncBatch(batch: HealthSyncBatch): { importedCount: number; duplicateCount: number } {
    let imported = 0;
    let duplicates = 0;

    const db = DatabaseService.getDb();

    // 1. Process Exercise / Activities
    if (batch.activities) {
      for (const act of batch.activities) {
        const existing = db.prepare('SELECT id FROM exercise_sessions WHERE source = ? AND external_id = ?').get(batch.provider, act.externalId) as any;
        if (existing) {
          duplicates++;
        } else {
          ExerciseService.logSession({
            userId: batch.userId,
            exerciseId: act.type.toLowerCase(),
            startedAt: new Date(act.startedAt),
            endedAt: act.endedAt ? new Date(act.endedAt) : undefined,
            durationSec: act.durationSec,
            quantity: act.quantity,
            unit: (act.unit as any) || 'SECONDS',
            source: batch.provider as any,
            externalId: act.externalId
          });
          imported++;
        }
      }
    }

    // 2. Process Sleep
    if (batch.sleep) {
      for (const sl of batch.sleep) {
        const existing = db.prepare('SELECT id FROM sleep_sessions WHERE source = ? AND external_id = ?').get(batch.provider, sl.externalId) as any;
        if (existing) {
          duplicates++;
        } else {
          SleepService.logSleep({
            userId: batch.userId,
            startedAt: new Date(sl.startedAt),
            endedAt: new Date(sl.endedAt),
            quality: sl.quality,
            source: batch.provider,
            externalId: sl.externalId
          });
          imported++;
        }
      }
    }

    // 3. Process Hydration
    if (batch.hydration) {
      for (const h of batch.hydration) {
        const existing = db.prepare('SELECT id FROM hydration_entries WHERE source = ? AND external_id = ?').get(batch.provider, h.externalId) as any;
        if (existing) {
          duplicates++;
        } else {
          HydrationService.logHydration({
            userId: batch.userId,
            amountMl: h.amountMl,
            timestamp: new Date(h.timestamp),
            source: batch.provider,
            externalId: h.externalId
          });
          imported++;
        }
      }
    }

    // Update last sync time on connection
    db.prepare('UPDATE health_provider_connections SET last_sync_at = ?, updated_at = ? WHERE user_id = ? AND provider = ?').run(
      new Date().toISOString(),
      new Date().toISOString(),
      batch.userId,
      batch.provider
    );

    return { importedCount: imported, duplicateCount: duplicates };
  }

  /**
   * Connects a health provider
   */
  public static connectProvider(params: {
    userId: string;
    provider: 'APPLE_HEALTH' | 'HEALTH_CONNECT' | 'MANUAL';
    permissions?: { exercise: boolean; steps: boolean; sleep: boolean; heartRate: boolean };
  }) {
    const db = DatabaseService.getDb();
    const connId = uuidv4();
    const now = new Date().toISOString();
    const perms = params.permissions || { exercise: true, steps: true, sleep: true, heartRate: false };

    db.prepare(`
      INSERT OR REPLACE INTO health_provider_connections (
        id, user_id, provider, status, permissions, created_at, updated_at
      ) VALUES (?, ?, ?, 'CONNECTED', ?, ?, ?)
    `).run(connId, params.userId, params.provider, JSON.stringify(perms), now, now);

    return { success: true, provider: params.provider, status: 'CONNECTED' };
  }

  /**
   * Disconnects a health provider
   */
  public static disconnectProvider(userId: string, provider: string) {
    const db = DatabaseService.getDb();
    db.prepare("UPDATE health_provider_connections SET status = 'DISCONNECTED', updated_at = ? WHERE user_id = ? AND provider = ?").run(
      new Date().toISOString(),
      userId,
      provider
    );
    return { success: true, provider, status: 'DISCONNECTED' };
  }
}
