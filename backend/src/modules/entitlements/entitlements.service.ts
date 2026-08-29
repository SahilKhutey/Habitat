// Entitlement Domain Entity & Service
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';

export type EntitlementCode = 'AI_COACH' | 'ADVANCED_ANALYTICS' | 'SMART_PLANNER' | 'GROUP_CHALLENGES' | 'UNLIMITED_ROUTINES';

export interface EntitlementEntity {
  id: string;
  code: EntitlementCode;
  name: string;
  createdAt: Date;
}

export interface UserEntitlementEntity {
  id: string;
  userId: string;
  entitlementId: string;
  source: 'FREE' | 'PLUS' | 'PRO' | 'MANUAL';
  expiresAt?: Date | null;
}

export class EntitlementsService {
  public static hasEntitlement(userId: string, code: EntitlementCode): boolean {
    const db = DatabaseService.getDb();
    const row = db.prepare(`
      SELECT ue.id FROM user_entitlements ue
      JOIN entitlements e ON ue.entitlement_id = e.id
      WHERE ue.user_id = ? AND e.code = ?
      AND (ue.expires_at IS NULL OR ue.expires_at > datetime('now'))
    `).get(userId, code);

    return !!row;
  }

  public static grantEntitlement(userId: string, code: EntitlementCode, source: 'FREE' | 'PLUS' | 'PRO' | 'MANUAL' = 'PRO', durationDays?: number): void {
    const db = DatabaseService.getDb();
    const ent = db.prepare('SELECT id FROM entitlements WHERE code = ?').get(code) as any;
    if (!ent) return;

    const id = uuidv4();
    const expiresAt = durationDays ? new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000).toISOString() : null;

    db.prepare(`
      INSERT OR REPLACE INTO user_entitlements (id, user_id, entitlement_id, source, expires_at, created_at)
      VALUES (?, ?, ?, ?, ?, datetime('now'))
    `).run(id, userId, ent.id, source, expiresAt);
  }
}
