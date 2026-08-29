// Clean Architecture Task Repository with Dual Implementation (SQLite + Prisma PostgreSQL)
import { DatabaseService } from '../db/connection';
import { PrismaService } from '../db/prisma';
import { PrismaClient } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';

export interface TaskEntity {
  id: string;
  userId: string | null;
  slug: string;
  title: string;
  description: string;
  category: string;
  difficulty: string;
  proofType: string;
  verificationType: string;
  baseXp: number;
  estimatedDurationSec: number;
  iconName: string;
  instructions: string;
  validationRules: Record<string, any>;
  isStarter: boolean;
  createdAt: string;
}

export interface CreateTaskInput {
  userId?: string;
  slug: string;
  title: string;
  description: string;
  category: string;
  difficulty?: 'EASY' | 'MEDIUM' | 'HARD' | string;
  proofType: 'PHOTO' | 'VIDEO' | 'HARDWARE_ANCHOR' | string;
  verificationType?: 'BASIC' | 'SMART_CV' | 'AI_POSE_REP_COUNTER' | 'HARDWARE_TOKEN' | string;
  baseXp?: number;
  estimatedDurationSec?: number;
  iconName?: string;
  instructions?: string;
  validationRules?: Record<string, any>;
  isStarter?: boolean;
}

export interface ITaskRepository {
  findById(id: string): Promise<TaskEntity | null> | (TaskEntity | null);
  findBySlug(slug: string): Promise<TaskEntity | null> | (TaskEntity | null);
  findAll(): Promise<TaskEntity[]> | TaskEntity[];
  create(params: CreateTaskInput): Promise<TaskEntity> | TaskEntity;
  getUserTasks(userId: string): Promise<TaskEntity[]> | TaskEntity[];
}

/**
 * SQLite Implementation of Task Repository
 */
export class SqliteTaskRepository implements ITaskRepository {
  public findById(id: string): TaskEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM tasks WHERE id = ?').get(id) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public findBySlug(slug: string): TaskEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM tasks WHERE slug = ?').get(slug) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public findAll(): TaskEntity[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM tasks ORDER BY created_at ASC').all() as any[];
    return rows.map(this.mapRow);
  }

  public create(params: CreateTaskInput): TaskEntity {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO tasks (id, user_id, slug, title, description, category, difficulty, proof_type, verification_type, base_xp, estimated_duration_sec, icon_name, instructions, validation_rules, is_starter, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      id,
      params.userId || null,
      params.slug,
      params.title,
      params.description,
      params.category,
      params.difficulty || 'MEDIUM',
      params.proofType,
      params.verificationType || 'BASIC',
      params.baseXp || 50,
      params.estimatedDurationSec || 60,
      params.iconName || 'hotel',
      params.instructions || 'Execute required actions.',
      JSON.stringify(params.validationRules || {}),
      params.isStarter ? 1 : 0,
      now
    );

    return this.findById(id)!;
  }

  public getUserTasks(userId: string): TaskEntity[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare(`
      SELECT * FROM tasks 
      WHERE user_id = ? OR user_id IS NULL 
      ORDER BY is_starter DESC, created_at ASC
    `).all(userId) as any[];

    return rows.map(this.mapRow);
  }

  private mapRow(row: any): TaskEntity {
    return {
      id: row.id,
      userId: row.user_id,
      slug: row.slug,
      title: row.title,
      description: row.description,
      category: row.category,
      difficulty: String(row.difficulty),
      proofType: row.proof_type,
      verificationType: row.verification_type,
      baseXp: Number(row.base_xp),
      estimatedDurationSec: Number(row.estimated_duration_sec),
      iconName: row.icon_name,
      instructions: row.instructions,
      validationRules: typeof row.validation_rules === 'string' ? JSON.parse(row.validation_rules || '{}') : (row.validation_rules || {}),
      isStarter: Boolean(row.is_starter),
      createdAt: row.created_at
    };
  }
}

/**
 * Prisma PostgreSQL Implementation of Task Repository
 */
export class PrismaTaskRepository implements ITaskRepository {
  constructor(private readonly db: PrismaClient) {}

  public async findById(id: string): Promise<TaskEntity | null> {
    const task = await this.db.task.findUnique({
      where: { id }
    });
    if (!task) return null;
    return this.mapPrismaModel(task);
  }

  public async findBySlug(slug: string): Promise<TaskEntity | null> {
    const task = await this.db.task.findUnique({
      where: { slug }
    });
    if (!task) return null;
    return this.mapPrismaModel(task);
  }

  public async findAll(): Promise<TaskEntity[]> {
    const tasks = await this.db.task.findMany({
      orderBy: { createdAt: 'asc' }
    });
    return tasks.map(this.mapPrismaModel);
  }

  public async create(params: CreateTaskInput): Promise<TaskEntity> {
    const task = await this.db.task.create({
      data: {
        userId: params.userId || null,
        slug: params.slug,
        title: params.title,
        description: params.description,
        category: params.category,
        difficulty: typeof params.difficulty === 'number' ? params.difficulty : 2,
        proofType: params.proofType,
        verificationType: params.verificationType || 'BASIC',
        baseXp: params.baseXp || 50,
        estimatedDurationSec: params.estimatedDurationSec || 60,
        iconName: params.iconName || 'hotel',
        instructions: params.instructions || 'Execute required actions.',
        validationRules: JSON.stringify(params.validationRules || {}),
        isStarter: Boolean(params.isStarter)
      }
    });

    return this.mapPrismaModel(task);
  }

  public async getUserTasks(userId: string): Promise<TaskEntity[]> {
    const tasks = await this.db.task.findMany({
      where: {
        OR: [{ userId }, { userId: null }]
      },
      orderBy: [
        { isStarter: 'desc' },
        { createdAt: 'asc' }
      ]
    });

    return tasks.map(this.mapPrismaModel);
  }

  private mapPrismaModel(task: any): TaskEntity {
    return {
      id: task.id,
      userId: task.userId,
      slug: task.slug,
      title: task.title,
      description: task.description,
      category: task.category,
      difficulty: String(task.difficulty),
      proofType: task.proofType,
      verificationType: task.verificationType,
      baseXp: task.baseXp,
      estimatedDurationSec: task.estimatedDurationSec,
      iconName: task.iconName,
      instructions: task.instructions,
      validationRules: typeof task.validationRules === 'string' ? JSON.parse(task.validationRules || '{}') : (task.validationRules || {}),
      isStarter: task.isStarter,
      createdAt: task.createdAt instanceof Date ? task.createdAt.toISOString() : String(task.createdAt)
    };
  }
}

/**
 * Facade maintaining 100% backward-compatible static API
 */
export class TaskRepository {
  private static sqliteAdapter = new SqliteTaskRepository();
  private static prismaAdapter: PrismaTaskRepository | null = null;

  public static findById(id: string): TaskEntity | null {
    return this.sqliteAdapter.findById(id);
  }

  public static findBySlug(slug: string): TaskEntity | null {
    return this.sqliteAdapter.findBySlug(slug);
  }

  public static findAll(): TaskEntity[] {
    return this.sqliteAdapter.findAll();
  }

  public static create(params: CreateTaskInput): TaskEntity {
    return this.sqliteAdapter.create(params);
  }

  public static getUserTasks(userId: string): TaskEntity[] {
    return this.sqliteAdapter.getUserTasks(userId);
  }
}
