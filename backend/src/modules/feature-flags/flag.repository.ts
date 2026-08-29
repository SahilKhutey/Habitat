// Feature Flags Repository & Guard
import { DatabaseService } from '../../db/connection';
import { FeatureFlagEntity, FeatureFlagKey } from './flag.types';

export class FlagRepository {
  public static getFlag(key: FeatureFlagKey): FeatureFlagEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT key, enabled, rollout_percentage as rolloutPercentage, description FROM feature_flags WHERE key = ?').get(key) as any;
    if (!row) return null;
    return {
      key: row.key,
      enabled: row.enabled === 1,
      rolloutPercentage: row.rolloutPercentage || 100,
      description: row.description
    };
  }

  public static setFlag(key: FeatureFlagKey, enabled: boolean, rolloutPercentage: number = 100): void {
    const db = DatabaseService.getDb();
    db.prepare(`
      INSERT OR REPLACE INTO feature_flags (key, enabled, rollout_percentage, updated_at)
      VALUES (?, ?, ?, datetime('now'))
    `).run(key, enabled ? 1 : 0, rolloutPercentage);
  }
}
