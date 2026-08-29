// Dynamic Feature Flags & Remote Configuration Service
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';

export class FeatureFlagService {
  /**
   * Checks whether a feature flag is enabled
   */
  public static isEnabled(key: string, defaultValue: boolean = true): boolean {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT is_enabled FROM feature_flags WHERE key = ?').get(key) as any;
    if (!row) return defaultValue;
    return Boolean(row.is_enabled);
  }

  /**
   * Sets or updates a feature flag
   */
  public static setFlag(key: string, isEnabled: boolean, description?: string) {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO feature_flags (id, key, is_enabled, description, created_at)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(key) DO UPDATE SET is_enabled = excluded.is_enabled
    `).run(id, key, isEnabled ? 1 : 0, description || null, now);

    return { key, isEnabled };
  }
}
