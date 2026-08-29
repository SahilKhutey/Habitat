// User Repository Interface & Dual Implementations (SQLite + Prisma PostgreSQL)
import { DatabaseService } from '../db/connection';
import { PrismaService } from '../db/prisma';
import { PrismaClient } from '@prisma/client';
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

export interface CreateUserInput {
  email: string;
  passwordHash: string;
  displayName: string;
  timezone?: string;
}

export interface IUserRepository {
  findById(id: string): Promise<UserEntity | null> | (UserEntity | null);
  findByEmail(email: string): Promise<UserEntity | null> | (UserEntity | null);
  create(params: CreateUserInput): Promise<UserEntity> | UserEntity;
}

/**
 * SQLite Implementation of User Repository
 */
export class SqliteUserRepository implements IUserRepository {
  public findById(id: string): UserEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM users WHERE id = ?').get(id) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public findByEmail(email: string): UserEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM users WHERE email = ?').get(email.toLowerCase().trim()) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public create(params: CreateUserInput): UserEntity {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO users (id, email, password_hash, display_name, timezone, discipline_score, autonomy_level, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, 100, 1, ?, ?)
    `).run(id, params.email.toLowerCase().trim(), params.passwordHash, params.displayName, params.timezone || 'UTC', now, now);

    return this.findById(id)!;
  }

  private mapRow(row: any): UserEntity {
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

/**
 * Prisma PostgreSQL Implementation of User Repository
 */
export class PrismaUserRepository implements IUserRepository {
  constructor(private readonly db: PrismaClient) {}

  public async findById(id: string): Promise<UserEntity | null> {
    const user = await this.db.user.findUnique({
      where: { id }
    });
    if (!user) return null;
    return this.mapPrismaModel(user);
  }

  public async findByEmail(email: string): Promise<UserEntity | null> {
    const user = await this.db.user.findUnique({
      where: { email: email.toLowerCase().trim() }
    });
    if (!user) return null;
    return this.mapPrismaModel(user);
  }

  public async create(params: CreateUserInput): Promise<UserEntity> {
    const user = await this.db.user.create({
      data: {
        email: params.email.toLowerCase().trim(),
        passwordHash: params.passwordHash,
        displayName: params.displayName,
        timezone: params.timezone || 'UTC',
        disciplineScore: 100,
        autonomyLevel: 1
      }
    });

    return this.mapPrismaModel(user);
  }

  private mapPrismaModel(user: any): UserEntity {
    return {
      id: user.id,
      email: user.email,
      passwordHash: user.passwordHash,
      displayName: user.displayName,
      timezone: user.timezone,
      disciplineScore: user.disciplineScore,
      autonomyLevel: user.autonomyLevel,
      createdAt: user.createdAt instanceof Date ? user.createdAt.toISOString() : String(user.createdAt),
      updatedAt: user.updatedAt instanceof Date ? user.updatedAt.toISOString() : String(user.updatedAt)
    };
  }
}

/**
 * Facade maintaining 100% backward-compatible static API
 */
export class UserRepository {
  private static sqliteAdapter = new SqliteUserRepository();

  public static findById(id: string): UserEntity | null {
    return this.sqliteAdapter.findById(id);
  }

  public static findByEmail(email: string): UserEntity | null {
    return this.sqliteAdapter.findByEmail(email);
  }

  public static create(params: CreateUserInput): UserEntity {
    return this.sqliteAdapter.create(params);
  }

  public static async findByIdAsync(id: string): Promise<UserEntity | null> {
    const { DatabaseFactory } = await import('../db/database.factory');
    return DatabaseFactory.getRepositories().users.findById(id);
  }

  public static async findByEmailAsync(email: string): Promise<UserEntity | null> {
    const { DatabaseFactory } = await import('../db/database.factory');
    return DatabaseFactory.getRepositories().users.findByEmail(email);
  }

  public static async createAsync(params: CreateUserInput): Promise<UserEntity> {
    const { DatabaseFactory } = await import('../db/database.factory');
    return DatabaseFactory.getRepositories().users.create(params);
  }
}
