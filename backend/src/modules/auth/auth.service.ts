// Authentication Service (JWT & Password Hash)
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import * as crypto from 'crypto';

const JWT_SECRET = process.env.JWT_SECRET || 'habitat-discipline-secret-key-2026';

export class AuthService {
  public static hashPassword(password: string): string {
    return crypto.createHash('sha256').update(password).digest('hex');
  }

  public static generateToken(user: { id: string; email: string; displayName: string }): string {
    const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
    const payload = Buffer.from(
      JSON.stringify({
        sub: user.id,
        email: user.email,
        displayName: user.displayName,
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60 // 30-day token
      })
    ).toString('base64url');

    const signature = crypto
      .createHmac('sha256', JWT_SECRET)
      .update(`${header}.${payload}`)
      .digest('base64url');

    return `${header}.${payload}.${signature}`;
  }

  public static verifyToken(token: string): { sub: string; email: string; displayName: string } | null {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) return null;

      const [header, payload, signature] = parts;
      const expectedSignature = crypto
        .createHmac('sha256', JWT_SECRET)
        .update(`${header}.${payload}`)
        .digest('base64url');

      if (signature !== expectedSignature) return null;

      const decoded = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
      if (decoded.exp && decoded.exp < Math.floor(Date.now() / 1000)) {
        return null; // Expired
      }

      return decoded;
    } catch (e) {
      return null;
    }
  }

  public static register(params: {
    email: string;
    password: string;
    displayName: string;
    timezone?: string;
  }) {
    const db = DatabaseService.getDb();
    const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(params.email.toLowerCase().trim());
    if (existing) {
      throw new Error('User with this email already exists.');
    }

    const id = uuidv4();
    const passwordHash = this.hashPassword(params.password);
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO users (id, email, password_hash, display_name, timezone, discipline_score, autonomy_level, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, 100, 1, ?, ?)
    `).run(
      id,
      params.email.toLowerCase().trim(),
      passwordHash,
      params.displayName.trim(),
      params.timezone || 'UTC',
      now,
      now
    );

    // Initialize streak record
    db.prepare(`
      INSERT INTO streaks (user_id, current_streak, longest_streak, grace_tokens, updated_at)
      VALUES (?, 0, 0, 1, ?)
    `).run(id, now);

    // Initial Welcome XP Transaction
    db.prepare(`
      INSERT INTO xp_transactions (id, user_id, amount, reason, created_at)
      VALUES (?, ?, 100, 'WELCOME_ONBOARDING_BONUS', ?)
    `).run(uuidv4(), id, now);

    const user = this.getUserById(id)!;
    const token = this.generateToken(user);

    return { user, token };
  }

  public static login(params: { email: string; password: string }) {
    const db = DatabaseService.getDb();
    const passwordHash = this.hashPassword(params.password);
    const row = db.prepare('SELECT * FROM users WHERE email = ? AND password_hash = ?').get(
      params.email.toLowerCase().trim(),
      passwordHash
    ) as any;

    if (!row) {
      throw new Error('Invalid email or password.');
    }

    const user = {
      id: row.id,
      email: row.email,
      displayName: row.display_name,
      timezone: row.timezone,
      disciplineScore: row.discipline_score,
      autonomyLevel: row.autonomy_level,
      createdAt: row.created_at
    };

    const token = this.generateToken(user);
    return { user, token };
  }

  public static getUserById(id: string) {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM users WHERE id = ?').get(id) as any;
    if (!row) return null;

    const streak = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(id) as any;
    const xpSum = db.prepare('SELECT SUM(amount) as total FROM xp_transactions WHERE user_id = ?').get(id) as any;

    return {
      id: row.id,
      email: row.email,
      displayName: row.display_name,
      timezone: row.timezone,
      disciplineScore: row.discipline_score,
      autonomyLevel: row.autonomy_level,
      currentStreak: streak?.current_streak ?? 0,
      longestStreak: streak?.longest_streak ?? 0,
      graceTokens: streak?.grace_tokens ?? 1,
      totalXp: xpSum?.total ?? 0,
      createdAt: row.created_at
    };
  }
}
