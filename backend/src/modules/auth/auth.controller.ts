// Production-Grade Authentication & User Identity Controller
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { AuthSecurity } from './auth.security';
import { authGuard, AuthenticatedRequest } from '../../common/guards/auth.guard';
import { v4 as uuidv4 } from 'uuid';

export class AuthService {
  public static register(params: {
    email: string;
    password: string;
    displayName: string;
    timezone?: string;
  }) {
    const db = DatabaseService.getDb();
    const cleanEmail = params.email.toLowerCase().trim();

    // 1. Validation
    if (!cleanEmail || !cleanEmail.includes('@')) {
      throw new Error('Valid email address is required.');
    }
    if (!params.password || params.password.length < 8) {
      throw new Error('Password must be at least 8 characters long.');
    }
    if (!params.displayName || params.displayName.trim().length === 0) {
      throw new Error('Display name is required.');
    }

    // 2. Check for duplicate email
    const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(cleanEmail);
    if (existing) {
      throw new Error('An account with this email already exists.');
    }

    const userId = uuidv4();
    const passwordHash = AuthSecurity.hashPassword(params.password);
    const now = new Date().toISOString();
    const timezone = params.timezone || 'UTC';

    // 3. Insert User
    db.prepare(`
      INSERT INTO users (id, email, password_hash, display_name, timezone, discipline_score, autonomy_level, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, 100, 1, ?, ?)
    `).run(userId, cleanEmail, passwordHash, params.displayName.trim(), timezone, now, now);

    // 4. Seed Default User Preferences
    db.prepare(`
      INSERT INTO user_preferences (user_id, theme, notifications_enabled, sound_enabled, vibration_enabled, motivational_feedback, reduced_motion, updated_at)
      VALUES (?, 'system', 1, 1, 1, 1, 0, ?)
    `).run(userId, now);

    // 5. Initialize Streaks & Deposit 100 XP Registration Bonus
    db.prepare(`
      INSERT INTO streaks (user_id, current_streak, longest_streak, grace_tokens, updated_at)
      VALUES (?, 0, 0, 1, ?)
    `).run(userId, now);

    db.prepare(`
      INSERT INTO xp_transactions (id, user_id, amount, reason, created_at)
      VALUES (?, ?, 100, 'NEW_RECRUIT_BONUS', ?)
    `).run(uuidv4(), userId, now);

    // 6. Generate Token Pair
    const tokens = AuthSecurity.generateTokens(userId, cleanEmail);

    return {
      user: {
        id: userId,
        email: cleanEmail,
        displayName: params.displayName.trim(),
        timezone,
        disciplineScore: 100,
        autonomyLevel: 1,
        createdAt: now
      },
      ...tokens
    };
  }

  public static login(params: { email: string; password: string }) {
    const db = DatabaseService.getDb();
    const cleanEmail = params.email.toLowerCase().trim();

    const user = db.prepare('SELECT * FROM users WHERE email = ?').get(cleanEmail) as any;
    if (!user) {
      throw new Error('Invalid email or password.');
    }

    const isValidPassword = AuthSecurity.verifyPassword(params.password, user.password_hash);
    if (!isValidPassword) {
      throw new Error('Invalid email or password.');
    }

    const tokens = AuthSecurity.generateTokens(user.id, user.email);

    return {
      user: {
        id: user.id,
        email: user.email,
        displayName: user.display_name,
        timezone: user.timezone,
        disciplineScore: user.discipline_score,
        autonomyLevel: user.autonomy_level,
        createdAt: user.created_at
      },
      ...tokens
    };
  }

  public static refresh(refreshToken: string) {
    const payload = AuthSecurity.verifyJwt(refreshToken);
    if (!payload || payload.type !== 'refresh') {
      throw new Error('Expected valid refresh token.');
    }

    const db = DatabaseService.getDb();
    const user = db.prepare('SELECT id, email FROM users WHERE id = ?').get(payload.userId) as any;
    if (!user) {
      throw new Error('User no longer exists.');
    }

    return AuthSecurity.generateTokens(user.id, user.email);
  }

  public static getMe(userId: string) {
    const db = DatabaseService.getDb();
    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(userId) as any;
    if (!user) throw new Error('User not found.');

    const prefs = db.prepare('SELECT * FROM user_preferences WHERE user_id = ?').get(userId) as any;
    const streak = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(userId) as any;
    const xpRow = db.prepare('SELECT COALESCE(SUM(amount), 0) as total FROM xp_transactions WHERE user_id = ?').get(userId) as any;

    return {
      id: user.id,
      email: user.email,
      displayName: user.display_name,
      timezone: user.timezone,
      disciplineScore: user.discipline_score,
      autonomyLevel: user.autonomy_level,
      totalXp: xpRow?.total ?? 0,
      streak: {
        current: streak?.current_streak ?? 0,
        longest: streak?.longest_streak ?? 0,
        graceTokens: streak?.grace_tokens ?? 1
      },
      preferences: {
        theme: prefs?.theme ?? 'system',
        notificationsEnabled: Boolean(prefs?.notifications_enabled ?? 1),
        soundEnabled: Boolean(prefs?.sound_enabled ?? 1),
        vibrationEnabled: Boolean(prefs?.vibration_enabled ?? 1),
        motivationalFeedback: Boolean(prefs?.motivational_feedback ?? 1),
        reducedMotion: Boolean(prefs?.reduced_motion ?? 0)
      }
    };
  }
}

export const authController = Router();

// POST /api/v1/auth/register
authController.post('/register', (req: Request, res: Response) => {
  try {
    const result = AuthService.register(req.body);
    res.status(201).json({ success: true, data: result });
  } catch (err: any) {
    res.status(400).json({ success: false, error: { code: 'REGISTRATION_FAILED', message: err.message } });
  }
});

// POST /api/v1/auth/login
authController.post('/login', (req: Request, res: Response) => {
  try {
    const result = AuthService.login(req.body);
    res.json({ success: true, data: result });
  } catch (err: any) {
    res.status(401).json({ success: false, error: { code: 'INVALID_CREDENTIALS', message: err.message } });
  }
});

// POST /api/v1/auth/refresh
authController.post('/refresh', (req: Request, res: Response) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      res.status(400).json({ success: false, error: { code: 'MISSING_REFRESH_TOKEN', message: 'refreshToken is required.' } });
      return;
    }
    const result = AuthService.refresh(refreshToken);
    res.json({ success: true, data: result });
  } catch (err: any) {
    res.status(401).json({ success: false, error: { code: 'INVALID_REFRESH_TOKEN', message: err.message } });
  }
});

// POST /api/v1/auth/logout
authController.post('/logout', (req: Request, res: Response) => {
  res.json({ success: true, message: 'Successfully logged out.' });
});

// GET /api/v1/auth/me (Protected)
authController.get('/me', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const me = AuthService.getMe(req.user!.userId);
    res.json({ success: true, data: me });
  } catch (err: any) {
    res.status(404).json({ success: false, error: { code: 'USER_NOT_FOUND', message: err.message } });
  }
});
