// Hydration Tracking Service
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { HydrationEntryEntity } from '../domain/hydration.entity';

export class HydrationService {
  /**
   * Logs a hydration entry in milliliters (ml)
   */
  public static logHydration(params: {
    userId: string;
    amountMl: number;
    timestamp?: Date;
    source?: string;
    externalId?: string;
  }): HydrationEntryEntity {
    if (params.amountMl <= 0) {
      throw new Error('INVALID_AMOUNT: Hydration amount must be greater than 0 ml');
    }

    const db = DatabaseService.getDb();
    const id = uuidv4();
    const ts = (params.timestamp || new Date()).toISOString();
    const now = new Date();
    const source = params.source || 'APP';

    // Duplicate check
    if (params.externalId) {
      const existing = db.prepare('SELECT id FROM hydration_entries WHERE source = ? AND external_id = ?').get(source, params.externalId) as any;
      if (existing) {
        const row = db.prepare('SELECT * FROM hydration_entries WHERE id = ?').get(existing.id) as any;
        return {
          id: row.id,
          userId: row.user_id,
          amountMl: row.amount_ml,
          timestamp: new Date(row.timestamp),
          source: row.source,
          externalId: row.external_id,
          createdAt: new Date(row.created_at)
        };
      }
    }

    db.prepare(`
      INSERT INTO hydration_entries (id, user_id, amount_ml, timestamp, source, external_id, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(id, params.userId, Math.round(params.amountMl), ts, source, params.externalId || null, now.toISOString());

    return {
      id,
      userId: params.userId,
      amountMl: Math.round(params.amountMl),
      timestamp: new Date(ts),
      source,
      externalId: params.externalId,
      createdAt: now
    };
  }

  /**
   * Retrieves today's total hydration and progress towards target (default 2500 ml)
   */
  public static getTodayHydration(userId: string, targetMl: number = 2500, dateStr?: string) {
    const db = DatabaseService.getDb();
    const targetDate = dateStr || new Date().toISOString().substring(0, 10);

    const row = db.prepare(`
      SELECT SUM(amount_ml) as total_ml
      FROM hydration_entries
      WHERE user_id = ? AND timestamp LIKE ?
    `).get(userId, `${targetDate}%`) as any;

    const totalMl = Number(row?.total_ml) || 0;
    const progressPercent = targetMl > 0 ? Math.min(100, Math.round((totalMl / targetMl) * 100)) : 100;

    const entries = db.prepare(`
      SELECT * FROM hydration_entries
      WHERE user_id = ? AND timestamp LIKE ?
      ORDER BY timestamp DESC
    `).all(userId, `${targetDate}%`) as any[];

    return {
      date: targetDate,
      totalMl,
      targetMl,
      totalLiters: Number((totalMl / 1000).toFixed(2)),
      targetLiters: Number((targetMl / 1000).toFixed(2)),
      progressPercent,
      entriesCount: entries.length,
      entries: entries.map((e) => ({
        id: e.id,
        amountMl: e.amount_ml,
        timestamp: e.timestamp,
        source: e.source
      }))
    };
  }
}
