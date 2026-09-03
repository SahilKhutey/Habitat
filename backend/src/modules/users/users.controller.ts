// User Profile, Preferences & Device Token Controller
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { authGuard, AuthenticatedRequest } from '../../common/guards/auth.guard';
import { v4 as uuidv4 } from 'uuid';

export class UserService {
  public static updateProfile(userId: string, params: { displayName?: string; timezone?: string }) {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();

    db.prepare(`
      UPDATE users 
      SET display_name = COALESCE(?, display_name),
          timezone = COALESCE(?, timezone),
          updated_at = ?
      WHERE id = ?
    `).run(params.displayName || null, params.timezone || null, now, userId);

    return db.prepare('SELECT id, email, display_name, timezone, discipline_score, autonomy_level FROM users WHERE id = ?').get(userId);
  }

  public static getPreferences(userId: string) {
    const db = DatabaseService.getDb();
    let prefs = db.prepare('SELECT * FROM user_preferences WHERE user_id = ?').get(userId) as any;

    if (!prefs) {
      const now = new Date().toISOString();
      db.prepare(`
        INSERT INTO user_preferences (user_id, theme, notifications_enabled, sound_enabled, vibration_enabled, motivational_feedback, reduced_motion, updated_at)
        VALUES (?, 'system', 1, 1, 1, 1, 0, ?)
      `).run(userId, now);

      prefs = db.prepare('SELECT * FROM user_preferences WHERE user_id = ?').get(userId) as any;
    }

    return {
      theme: prefs.theme,
      notificationsEnabled: Boolean(prefs.notifications_enabled),
      soundEnabled: Boolean(prefs.sound_enabled),
      vibrationEnabled: Boolean(prefs.vibration_enabled),
      motivationalFeedback: Boolean(prefs.motivational_feedback),
      reducedMotion: Boolean(prefs.reduced_motion)
    };
  }

  public static updatePreferences(userId: string, params: {
    theme?: string;
    notificationsEnabled?: boolean;
    soundEnabled?: boolean;
    vibrationEnabled?: boolean;
    motivationalFeedback?: boolean;
    reducedMotion?: boolean;
  }) {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();

    db.prepare(`
      UPDATE user_preferences 
      SET theme = COALESCE(?, theme),
          notifications_enabled = COALESCE(?, notifications_enabled),
          sound_enabled = COALESCE(?, sound_enabled),
          vibration_enabled = COALESCE(?, vibration_enabled),
          motivational_feedback = COALESCE(?, motivational_feedback),
          reduced_motion = COALESCE(?, reduced_motion),
          updated_at = ?
      WHERE user_id = ?
    `).run(
      params.theme || null,
      params.notificationsEnabled !== undefined ? (params.notificationsEnabled ? 1 : 0) : null,
      params.soundEnabled !== undefined ? (params.soundEnabled ? 1 : 0) : null,
      params.vibrationEnabled !== undefined ? (params.vibrationEnabled ? 1 : 0) : null,
      params.motivationalFeedback !== undefined ? (params.motivationalFeedback ? 1 : 0) : null,
      params.reducedMotion !== undefined ? (params.reducedMotion ? 1 : 0) : null,
      now,
      userId
    );

    return this.getPreferences(userId);
  }

  public static registerDevice(userId: string, params: {
    platform: string;
    deviceIdentifier: string;
    pushToken?: string;
  }) {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO mesh_devices (id, user_id, device_name, device_type, push_token, last_ping_at, is_online, created_at)
      VALUES (?, ?, ?, ?, ?, ?, 1, ?)
    `).run(id, userId, params.deviceIdentifier, params.platform.toUpperCase(), params.pushToken || null, now, now);

    return {
      deviceId: id,
      userId,
      platform: params.platform,
      registeredAt: now
    };
  }
}

export const usersController = Router();

// GET /api/v1/users/current
usersController.get('/current', (req: Request, res: Response) => {
  const db = DatabaseService.getDb();
  const user = db.prepare('SELECT id, email, display_name, timezone, discipline_score, autonomy_level FROM users LIMIT 1').get();
  res.json({ success: true, data: user });
});

// GET /api/v1/users/profile
usersController.get('/profile', authGuard, (req: AuthenticatedRequest, res: Response) => {
  const db = DatabaseService.getDb();
  const user = db.prepare('SELECT id, email, display_name, timezone, discipline_score, autonomy_level FROM users WHERE id = ?').get(req.user!.userId);
  res.json({ success: true, data: user });
});

// PATCH /api/v1/users/profile
usersController.patch('/profile', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const updated = UserService.updateProfile(req.user!.userId, req.body);
    res.json({ success: true, data: updated });
  } catch (err: any) {
    res.status(400).json({ success: false, error: { message: err.message } });
  }
});

// GET /api/v1/users/preferences
usersController.get('/preferences', authGuard, (req: AuthenticatedRequest, res: Response) => {
  const prefs = UserService.getPreferences(req.user!.userId);
  res.json({ success: true, data: prefs });
});

// PATCH /api/v1/users/preferences
usersController.patch('/preferences', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const updated = UserService.updatePreferences(req.user!.userId, req.body);
    res.json({ success: true, data: updated });
  } catch (err: any) {
    res.status(400).json({ success: false, error: { message: err.message } });
  }
});

// POST /api/v1/users/devices/register
usersController.post('/devices/register', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const { platform, deviceIdentifier, pushToken } = req.body;
    if (!platform || !deviceIdentifier) {
      res.status(400).json({ success: false, error: { message: 'platform and deviceIdentifier required' } });
      return;
    }

    const device = UserService.registerDevice(req.user!.userId, { platform, deviceIdentifier, pushToken });
    res.status(201).json({ success: true, data: device });
  } catch (err: any) {
    res.status(400).json({ success: false, error: { message: err.message } });
  }
});
