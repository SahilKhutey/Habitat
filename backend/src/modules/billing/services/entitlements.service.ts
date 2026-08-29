// Entitlements & Subscription Verification Service
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';

export type EntitlementCode =
  | 'AI_COACH'
  | 'ADVANCED_ANALYTICS'
  | 'SMART_PLANNER'
  | 'GROUP_CHALLENGES'
  | 'UNLIMITED_ROUTINES';

export class EntitlementsService {
  /**
   * Authoritatively verifies whether a user has an active entitlement
   */
  public static hasEntitlement(userId: string, code: EntitlementCode): boolean {
    const db = DatabaseService.getDb();
    const row = db.prepare(`
      SELECT * FROM user_entitlements
      WHERE user_id = ? AND entitlement_code = ? AND status = 'ACTIVE'
    `).get(userId, code) as any;

    if (!row) return false;
    if (row.expires_at && new Date(row.expires_at) < new Date()) {
      return false;
    }
    return true;
  }

  /**
   * Grants an entitlement via verified server-side purchase
   */
  public static grantEntitlement(userId: string, code: EntitlementCode, durationDays?: number): { success: boolean } {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date();
    const expiresAt = durationDays ? new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000).toISOString() : null;

    db.prepare(`
      INSERT OR REPLACE INTO user_entitlements (id, user_id, entitlement_code, status, expires_at, created_at)
      VALUES (?, ?, ?, 'ACTIVE', ?, ?)
    `).run(id, userId, code, expiresAt, now.toISOString());

    return { success: true };
  }

  /**
   * Revokes an entitlement
   */
  public static revokeEntitlement(userId: string, code: EntitlementCode): { success: boolean } {
    const db = DatabaseService.getDb();
    db.prepare(`
      UPDATE user_entitlements SET status = 'REVOKED'
      WHERE user_id = ? AND entitlement_code = ?
    `).run(userId, code);

    return { success: true };
  }
}
