// Sleep Session & Foundation Service
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { SleepSessionEntity } from '../domain/hydration.entity';

export class SleepService {
  /**
   * Logs a sleep session
   */
  public static logSleep(params: {
    userId: string;
    startedAt: Date;
    endedAt: Date;
    source?: string;
    quality?: number;
    notes?: string;
    externalId?: string;
  }): SleepSessionEntity {
    if (params.endedAt <= params.startedAt) {
      throw new Error('INVALID_SLEEP_WINDOW: Sleep end time must be after start time');
    }

    const db = DatabaseService.getDb();
    const sessionId = uuidv4();
    const durationSec = Math.round((params.endedAt.getTime() - params.startedAt.getTime()) / 1000);
    const durationMin = Math.round(durationSec / 60);
    const now = new Date();
    const source = params.source || 'MANUAL';

    // Duplicate check
    if (params.externalId) {
      const existing = db.prepare('SELECT id FROM sleep_sessions WHERE source = ? AND external_id = ?').get(source, params.externalId) as any;
      if (existing) {
        const row = db.prepare('SELECT * FROM sleep_sessions WHERE id = ?').get(existing.id) as any;
        return {
          id: row.id,
          userId: row.user_id,
          startedAt: new Date(row.started_at || row.start_time),
          endedAt: new Date(row.ended_at || row.end_time),
          durationSec: row.duration_sec || row.duration_minutes * 60,
          source: row.source,
          quality: row.quality,
          notes: row.notes,
          externalId: row.external_id,
          createdAt: new Date(row.created_at)
        };
      }
    }

    db.prepare(`
      INSERT INTO sleep_sessions (
        id, user_id, start_time, end_time, started_at, ended_at, duration_minutes, duration_sec,
        deep_sleep_minutes, rem_sleep_minutes, recovery_score, source, quality, notes, external_id, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 80, ?, ?, ?, ?, ?)
    `).run(
      sessionId,
      params.userId,
      params.startedAt.toISOString(),
      params.endedAt.toISOString(),
      params.startedAt.toISOString(),
      params.endedAt.toISOString(),
      durationMin,
      durationSec,
      source,
      params.quality || null,
      params.notes || null,
      params.externalId || null,
      now.toISOString()
    );

    return {
      id: sessionId,
      userId: params.userId,
      startedAt: params.startedAt,
      endedAt: params.endedAt,
      durationSec,
      source,
      quality: params.quality,
      notes: params.notes,
      externalId: params.externalId,
      createdAt: now
    };
  }

  /**
   * Retrieves sleep overview and 7-day averages
   */
  public static getSleepOverview(userId: string) {
    const db = DatabaseService.getDb();
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

    const row = db.prepare(`
      SELECT 
        COUNT(*) as total_nights,
        AVG(CASE WHEN duration_sec > 0 THEN duration_sec ELSE duration_minutes * 60 END) as avg_duration_sec
      FROM sleep_sessions
      WHERE user_id = ? AND (started_at >= ? OR start_time >= ?)
    `).get(userId, sevenDaysAgo, sevenDaysAgo) as any;

    const avgSec = Math.round(Number(row?.avg_duration_sec) || 0);
    const avgHours = Number((avgSec / 3600).toFixed(1));

    const latest = db.prepare(`
      SELECT * FROM sleep_sessions
      WHERE user_id = ?
      ORDER BY created_at DESC LIMIT 1
    `).get(userId) as any;

    return {
      totalLoggedNights: Number(row?.total_nights) || 0,
      averageDurationHours: avgHours,
      averageDurationMinutes: Math.round(avgSec / 60),
      targetHours: 8.0,
      targetAdherencePercent: Math.min(100, Math.round((avgHours / 8.0) * 100)),
      lastNight: latest
        ? {
            startedAt: latest.started_at || latest.start_time,
            endedAt: latest.ended_at || latest.end_time,
            durationHours: Number(((latest.duration_sec || latest.duration_minutes * 60) / 3600).toFixed(1))
          }
        : null
    };
  }
}
