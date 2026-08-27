// Physical NFC / QR Hardware Anchors Controller & Service
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import * as crypto from 'crypto';
import { MissionsService } from '../missions/missions.controller';

export class AnchorsService {
  public static pairAnchor(params: {
    userId: string;
    name: string;
    anchorType: string; // 'NFC_TAG' | 'ROTATING_QR' | 'BLE_BEACON'
    locationLabel: string; // 'Bathroom Sink' | 'Kitchen Counter'
    hardwareIdentifier?: string;
  }) {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();
    const secretKey = crypto.randomBytes(32).toString('hex');
    const hwId = params.hardwareIdentifier || `HW-${Math.random().toString(36).substring(2, 10).toUpperCase()}`;

    db.prepare(`
      INSERT INTO physical_anchors (id, user_id, name, anchor_type, location_label, hardware_identifier, secret_key, is_active, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)
    `).run(
      id,
      params.userId,
      params.name.trim(),
      params.anchorType,
      params.locationLabel.trim(),
      hwId,
      secretKey,
      now
    );

    return this.getAnchorById(id);
  }

  public static getAnchors(userId: string) {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT id, user_id, name, anchor_type, location_label, hardware_identifier, is_active, created_at FROM physical_anchors WHERE user_id = ? AND is_active = 1').all(userId) as any[];

    return rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      name: r.name,
      anchorType: r.anchor_type,
      locationLabel: r.location_label,
      hardwareIdentifier: r.hardware_identifier,
      isActive: Boolean(r.is_active),
      createdAt: r.created_at
    }));
  }

  public static getAnchorById(id: string) {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT id, user_id, name, anchor_type, location_label, hardware_identifier, is_active, created_at FROM physical_anchors WHERE id = ?').get(id) as any;
    if (!row) return null;

    return {
      id: row.id,
      userId: row.user_id,
      name: row.name,
      anchorType: row.anchor_type,
      locationLabel: row.location_label,
      hardwareIdentifier: row.hardware_identifier,
      isActive: Boolean(row.is_active),
      createdAt: row.created_at
    };
  }

  public static generateChallenge(anchorId: string) {
    const db = DatabaseService.getDb();
    const anchor = db.prepare('SELECT * FROM physical_anchors WHERE id = ? AND is_active = 1').get(anchorId) as any;
    if (!anchor) {
      throw new Error('Physical anchor not found or inactive.');
    }

    const timestamp = Date.now();
    const nonce = crypto.randomBytes(16).toString('hex');
    const signature = crypto
      .createHmac('sha256', anchor.secret_key)
      .update(`${anchor.id}:${nonce}:${timestamp}`)
      .digest('hex');

    return {
      anchorId: anchor.id,
      nonce,
      timestamp,
      signature,
      expiresInSeconds: 60,
      challengePayload: `${anchor.id}:${nonce}:${timestamp}:${signature}`
    };
  }

  public static verifyAnchorScan(params: {
    userId: string;
    anchorId: string;
    challengePayload: string;
    missionId?: string;
  }) {
    const db = DatabaseService.getDb();
    const anchor = db.prepare('SELECT * FROM physical_anchors WHERE id = ? AND is_active = 1').get(params.anchorId) as any;
    if (!anchor) {
      return { isValid: false, reason: 'Unknown or inactive physical hardware anchor.' };
    }

    const parts = params.challengePayload.split(':');
    if (parts.length !== 4) {
      return { isValid: false, reason: 'Malformed challenge token payload.' };
    }

    const [scannedAnchorId, nonce, timestampStr, signature] = parts;
    if (scannedAnchorId !== anchor.id) {
      return { isValid: false, reason: 'Anchor ID mismatch.' };
    }

    const timestamp = parseInt(timestampStr, 10);
    const ageSeconds = Math.floor((Date.now() - timestamp) / 1000);

    // Replay attack / expiry check (60s max age)
    if (ageSeconds > 60 || ageSeconds < -5) {
      return { isValid: false, reason: `Challenge expired (${ageSeconds}s old). Tap physical anchor again.` };
    }

    // Duplicate nonce check (Replay prevention)
    const existingNonce = db.prepare('SELECT id FROM anchor_verifications WHERE nonce = ?').get(nonce) as any;
    if (existingNonce) {
      return { isValid: false, reason: 'Replay attack rejected: One-time physical nonce already used.' };
    }

    // Verify HMAC-SHA256 signature
    const expectedSignature = crypto
      .createHmac('sha256', anchor.secret_key)
      .update(`${anchor.id}:${nonce}:${timestamp}`)
      .digest('hex');

    if (signature !== expectedSignature) {
      return { isValid: false, reason: 'Invalid hardware cryptographic signature.' };
    }

    const now = new Date().toISOString();
    const logId = uuidv4();

    db.prepare(`
      INSERT INTO anchor_verifications (id, anchor_id, user_id, mission_id, nonce, verified_at)
      VALUES (?, ?, ?, ?, ?, ?)
    `).run(logId, anchor.id, params.userId, params.missionId || null, nonce, now);

    let completedMission = null;
    if (params.missionId) {
      completedMission = MissionsService.completeMission(params.missionId);
    }

    return {
      isValid: true,
      anchorName: anchor.name,
      locationLabel: anchor.location_label,
      verifiedAt: now,
      completedMission
    };
  }

  public static deleteAnchor(id: string, userId: string) {
    const db = DatabaseService.getDb();
    db.prepare('DELETE FROM physical_anchors WHERE id = ? AND user_id = ?').run(id, userId);
    return true;
  }
}

export const anchorsController = Router();

// GET /api/v1/anchors - List user's anchors
anchorsController.get('/', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const anchors = AnchorsService.getAnchors(userId);
  res.json({ success: true, count: anchors.length, data: anchors });
});

// POST /api/v1/anchors/pair - Pair new anchor
anchorsController.post('/pair', (req: Request, res: Response) => {
  try {
    const { userId, name, anchorType, locationLabel, hardwareIdentifier } = req.body;
    if (!name || !anchorType || !locationLabel) {
      res.status(400).json({ success: false, error: 'name, anchorType, and locationLabel are required' });
      return;
    }

    const anchor = AnchorsService.pairAnchor({
      userId: userId || 'default-user',
      name,
      anchorType,
      locationLabel,
      hardwareIdentifier
    });

    res.status(201).json({ success: true, data: anchor });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/anchors/:id/challenge - Generate time-bound nonce challenge
anchorsController.post('/:id/challenge', (req: Request, res: Response) => {
  try {
    const challenge = AnchorsService.generateChallenge(String(req.params.id));
    res.json({ success: true, data: challenge });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/anchors/verify - Verify physical hardware scan
anchorsController.post('/verify', (req: Request, res: Response) => {
  try {
    const { userId, anchorId, challengePayload, missionId } = req.body;
    if (!anchorId || !challengePayload) {
      res.status(400).json({ success: false, error: 'anchorId and challengePayload are required' });
      return;
    }

    const result = AnchorsService.verifyAnchorScan({
      userId: userId || 'default-user',
      anchorId,
      challengePayload,
      missionId
    });

    res.json({ success: result.isValid, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// DELETE /api/v1/anchors/:id - Delete anchor
anchorsController.delete('/:id', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const success = AnchorsService.deleteAnchor(String(req.params.id), userId);
  res.json({ success });
});
