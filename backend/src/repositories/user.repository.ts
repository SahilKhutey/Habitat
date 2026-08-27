// User Repository Interface & Implementation
import { DatabaseService } from '../db/connection';
import { v4 as uuidv4 } from 'uuid';

export interface UserEntity {
  id: string;
  email: string;
  passwordHash: string;
  displayName: string;
  timezone: string;
  disciplineScore: number;
  autonomyLevel: number;
  createdAt: string;
  updatedAt: string;
}

export class UserRepository {
  public static findById(id: string): UserEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM users WHERE id = ?').get(id) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public static findByEmail(email: string): UserEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM users WHERE email = ?').get(email.toLowerCase().trim()) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public static create(params: {
    email: string;
    passwordHash: string;
    displayName: string;
    timezone?: string;
  }): UserEntity {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO users (id, email, password_hash, display_name, timezone, discipline_score, autonomy_level, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, 100, 1, ?, ?)
    `).run(id, params.email.toLowerCase().trim(), params.passwordHash, params.displayName, params.timezone || 'UTC', now, now);

    return this.findById(id)!;
  }

  private static mapRow(row: any): UserEntity {
    return {
      id: row.id,
      email: row.email,
      passwordHash: row.password_hash,
      displayName: row.display_name,
      timezone: row.timezone,
      disciplineScore: row.discipline_score,
      autonomyLevel: row.autonomy_level,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };
  }
}
