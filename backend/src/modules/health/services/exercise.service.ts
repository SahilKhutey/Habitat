// Exercise Tracking & Session Management Service
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { ExerciseCategory, ExerciseSessionEntity, ExerciseSource, ExerciseUnit } from '../domain/exercise.entity';

export class ExerciseService {
  /**
   * Logs a new exercise session
   */
  public static logSession(params: {
    userId: string;
    exerciseId: string;
    startedAt?: Date;
    endedAt?: Date;
    durationSec?: number;
    quantity?: number;
    unit?: ExerciseUnit;
    sets?: number;
    notes?: string;
    source?: ExerciseSource;
    externalId?: string;
  }): ExerciseSessionEntity {
    if (params.durationSec !== undefined && params.durationSec < 0) {
      throw new Error('INVALID_DURATION: Duration cannot be negative');
    }
    if (params.quantity !== undefined && params.quantity < 0) {
      throw new Error('INVALID_QUANTITY: Quantity cannot be negative');
    }

    const db = DatabaseService.getDb();
    const sessionId = uuidv4();
    const now = new Date();
    const startedAt = params.startedAt || now;
    const endedAt = params.endedAt || (params.durationSec ? new Date(startedAt.getTime() + params.durationSec * 1000) : undefined);
    const duration = params.durationSec !== undefined
      ? params.durationSec
      : endedAt
      ? Math.max(0, Math.round((endedAt.getTime() - startedAt.getTime()) / 1000))
      : 0;

    // Check duplicate externalId
    if (params.externalId && params.source) {
      const existing = db.prepare('SELECT id FROM exercise_sessions WHERE source = ? AND external_id = ?').get(params.source, params.externalId) as any;
      if (existing) {
        const row = db.prepare('SELECT * FROM exercise_sessions WHERE id = ?').get(existing.id) as any;
        return {
          id: row.id,
          userId: row.user_id,
          exerciseId: row.exercise_id,
          startedAt: new Date(row.started_at),
          endedAt: row.ended_at ? new Date(row.ended_at) : undefined,
          durationSec: row.duration_sec,
          quantity: row.quantity,
          unit: row.unit,
          sets: row.sets,
          notes: row.notes,
          source: row.source,
          externalId: row.external_id,
          createdAt: new Date(row.created_at)
        };
      }
    }

    db.prepare(`
      INSERT INTO exercise_sessions (
        id, user_id, exercise_id, started_at, ended_at, duration_sec, quantity, unit, sets, notes, source, external_id, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      sessionId,
      params.userId,
      params.exerciseId,
      startedAt.toISOString(),
      endedAt ? endedAt.toISOString() : null,
      duration,
      params.quantity || 0,
      params.unit || 'REPETITIONS',
      params.sets || 1,
      params.notes || null,
      params.source || 'APP',
      params.externalId || null,
      now.toISOString()
    );

    return {
      id: sessionId,
      userId: params.userId,
      exerciseId: params.exerciseId,
      startedAt,
      endedAt,
      durationSec: duration,
      quantity: params.quantity,
      unit: params.unit || 'REPETITIONS',
      sets: params.sets || 1,
      notes: params.notes,
      source: params.source || 'APP',
      externalId: params.externalId,
      createdAt: now
    };
  }

  /**
   * Retrieves exercise sessions for a user
   */
  public static getSessions(userId: string, limit: number = 20): ExerciseSessionEntity[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare(`
      SELECT es.*, et.name as exercise_name
      FROM exercise_sessions es
      LEFT JOIN exercise_templates et ON es.exercise_id = et.id
      WHERE es.user_id = ?
      ORDER BY es.started_at DESC
      LIMIT ?
    `).all(userId, limit) as any[];

    return rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      exerciseId: r.exercise_id,
      exerciseName: r.exercise_name || r.exercise_id,
      startedAt: new Date(r.started_at),
      endedAt: r.ended_at ? new Date(r.ended_at) : undefined,
      durationSec: r.duration_sec,
      quantity: r.quantity,
      unit: r.unit,
      sets: r.sets,
      notes: r.notes,
      source: r.source,
      externalId: r.external_id,
      createdAt: new Date(r.created_at)
    }));
  }

  /**
   * Computes weekly exercise statistics
   */
  public static getWeeklyStats(userId: string) {
    const db = DatabaseService.getDb();
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

    const row = db.prepare(`
      SELECT 
        COUNT(*) as session_count,
        SUM(duration_sec) as total_duration_sec,
        SUM(quantity) as total_quantity
      FROM exercise_sessions
      WHERE user_id = ? AND started_at >= ?
    `).get(userId, sevenDaysAgo) as any;

    const totalSec = Number(row?.total_duration_sec) || 0;
    return {
      sessionCount: Number(row?.session_count) || 0,
      totalMinutes: Math.round(totalSec / 60),
      totalQuantity: Number(row?.total_quantity) || 0
    };
  }
}
