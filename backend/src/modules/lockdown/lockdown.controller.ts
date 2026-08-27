// Iron Fortress App Lockdown, Distraction Shield & Discipline Bond Controller
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';

export class LockdownService {
  public static getSettings(userId: string) {
    const db = DatabaseService.getDb();
    let row = db.prepare('SELECT * FROM lockdown_settings WHERE user_id = ?').get(userId) as any;

    if (!row) {
      // Create default settings if none exist
      const defaultBlocked = ['com.instagram.android', 'com.zhiliaoapp.musically', 'com.google.android.youtube', 'com.twitter.android', 'com.reddit.frontpage'];
      const id = uuidv4();
      const now = new Date().toISOString();

      db.prepare(`
        INSERT INTO lockdown_settings (id, user_id, is_shield_enabled, blocked_apps, quarantine_duration_min, strict_mode, created_at)
        VALUES (?, ?, 1, ?, 60, 1, ?)
      `).run(id, userId, JSON.stringify(defaultBlocked), now);

      row = db.prepare('SELECT * FROM lockdown_settings WHERE id = ?').get(id) as any;
    }

    const activeBonds = db.prepare("SELECT * FROM discipline_bonds WHERE user_id = ? AND status = 'ACTIVE'").all(userId) as any[];

    return {
      userId: row.user_id,
      isShieldEnabled: Boolean(row.is_shield_enabled),
      blockedApps: JSON.parse(row.blocked_apps || '[]'),
      quarantineDurationMinutes: row.quarantine_duration_min,
      strictMode: Boolean(row.strict_mode),
      activeBondsCount: activeBonds.length,
      activeBonds: activeBonds.map((b) => ({
        id: b.id,
        stakedXp: b.staked_xp,
        missionId: b.mission_id,
        status: b.status,
        createdAt: b.created_at
      }))
    };
  }

  public static updateSettings(params: {
    userId: string;
    isShieldEnabled?: boolean;
    blockedApps?: string[];
    quarantineDurationMinutes?: number;
    strictMode?: boolean;
  }) {
    const db = DatabaseService.getDb();
    const existing = db.prepare('SELECT id FROM lockdown_settings WHERE user_id = ?').get(params.userId) as any;

    if (existing) {
      db.prepare(`
        UPDATE lockdown_settings
        SET is_shield_enabled = COALESCE(?, is_shield_enabled),
            blocked_apps = COALESCE(?, blocked_apps),
            quarantine_duration_min = COALESCE(?, quarantine_duration_min),
            strict_mode = COALESCE(?, strict_mode)
        WHERE user_id = ?
      `).run(
        params.isShieldEnabled !== undefined ? (params.isShieldEnabled ? 1 : 0) : null,
        params.blockedApps ? JSON.stringify(params.blockedApps) : null,
        params.quarantineDurationMinutes ?? null,
        params.strictMode !== undefined ? (params.strictMode ? 1 : 0) : null,
        params.userId
      );
    } else {
      const id = uuidv4();
      db.prepare(`
        INSERT INTO lockdown_settings (id, user_id, is_shield_enabled, blocked_apps, quarantine_duration_min, strict_mode, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run(
        id,
        params.userId,
        params.isShieldEnabled !== false ? 1 : 0,
        JSON.stringify(params.blockedApps || []),
        params.quarantineDurationMinutes || 60,
        params.strictMode !== false ? 1 : 0,
        new Date().toISOString()
      );
    }

    return this.getSettings(params.userId);
  }

  public static stakeBond(params: { userId: string; stakedXp: number; missionId?: string }) {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO discipline_bonds (id, user_id, mission_id, staked_xp, status, created_at)
      VALUES (?, ?, ?, ?, 'ACTIVE', ?)
    `).run(id, params.userId, params.missionId || null, params.stakedXp, now);

    return {
      bondId: id,
      userId: params.userId,
      stakedXp: params.stakedXp,
      status: 'ACTIVE',
      createdAt: now
    };
  }

  public static settleBond(params: { bondId: string; isHonored: boolean; instantBonus?: boolean }) {
    const db = DatabaseService.getDb();
    const bond = db.prepare('SELECT * FROM discipline_bonds WHERE id = ?').get(params.bondId) as any;
    if (!bond) throw new Error('Bond not found.');

    const now = new Date().toISOString();
    const newStatus = params.isHonored ? 'HONORED' : 'FORFEITED';

    db.prepare(`
      UPDATE discipline_bonds 
      SET status = ?, settled_at = ?
      WHERE id = ?
    `).run(newStatus, now, params.bondId);

    // Ledger update
    if (params.isHonored) {
      const rewardXp = params.instantBonus ? Math.round(bond.staked_xp * 1.5) : bond.staked_xp;
      db.prepare(`
        INSERT INTO xp_transactions (id, user_id, mission_id, amount, reason, created_at)
        VALUES (?, ?, ?, ?, 'DISCIPLINE_BOND_HONORED_REWARD', ?)
      `).run(uuidv4(), bond.user_id, bond.mission_id, rewardXp, now);
    } else {
      // Forfeiture deduction
      db.prepare(`
        INSERT INTO xp_transactions (id, user_id, mission_id, amount, reason, created_at)
        VALUES (?, ?, ?, ?, 'DISCIPLINE_BOND_FORFEITED_PENALTY', ?)
      `).run(uuidv4(), bond.user_id, bond.mission_id, -bond.staked_xp, now);
    }

    return {
      bondId: bond.id,
      status: newStatus,
      stakedXp: bond.staked_xp,
      settledAt: now
    };
  }

  public static requestEmergencyBypass(params: { userId: string; reason: string }) {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO emergency_bypasses (id, user_id, reason, authorized_at)
      VALUES (?, ?, ?, ?)
    `).run(id, params.userId, params.reason.trim(), now);

    return {
      bypassId: id,
      authorized: true,
      unlockMinutes: 15,
      reason: params.reason,
      authorizedAt: now
    };
  }
}

export const lockdownController = Router();

// GET /api/v1/lockdown/settings
lockdownController.get('/settings', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const settings = LockdownService.getSettings(userId);
  res.json({ success: true, data: settings });
});

// POST /api/v1/lockdown/settings
lockdownController.post('/settings', (req: Request, res: Response) => {
  try {
    const { userId, isShieldEnabled, blockedApps, quarantineDurationMinutes, strictMode } = req.body;
    const updated = LockdownService.updateSettings({
      userId: userId || 'default-user',
      isShieldEnabled,
      blockedApps,
      quarantineDurationMinutes,
      strictMode
    });
    res.json({ success: true, data: updated });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/lockdown/bond/stake
lockdownController.post('/bond/stake', (req: Request, res: Response) => {
  try {
    const { userId, stakedXp, missionId } = req.body;
    if (!stakedXp || stakedXp <= 0) {
      res.status(400).json({ success: false, error: 'stakedXp must be greater than 0' });
      return;
    }

    const bond = LockdownService.stakeBond({
      userId: userId || 'default-user',
      stakedXp: parseInt(stakedXp, 10),
      missionId
    });

    res.status(201).json({ success: true, data: bond });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/lockdown/emergency-bypass
lockdownController.post('/emergency-bypass', (req: Request, res: Response) => {
  try {
    const { userId, reason } = req.body;
    if (!reason) {
      res.status(400).json({ success: false, error: 'Reason for emergency bypass is required' });
      return;
    }

    const bypass = LockdownService.requestEmergencyBypass({
      userId: userId || 'default-user',
      reason
    });

    res.json({ success: true, data: bypass });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});
