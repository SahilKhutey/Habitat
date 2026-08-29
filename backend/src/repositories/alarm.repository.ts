// Alarm Repository Interface & Dual Implementations (SQLite + Prisma PostgreSQL)
import { DatabaseService } from '../db/connection';
import { PrismaService } from '../db/prisma';
import { PrismaClient } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';

export interface AlarmEntity {
  id: string;
  userId: string;
  taskId: string;
  timeOfDay: string;
  timezone: string;
  repeatDays: number[];
  disciplineMode: 'GENTLE' | 'DISCIPLINE' | 'HARDCORE' | string;
  retryIntervalMinutes: number;
  isEnabled: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface CreateAlarmInput {
  userId: string;
  taskId: string;
  timeOfDay: string;
  timezone?: string;
  repeatDays: number[];
  disciplineMode?: 'GENTLE' | 'DISCIPLINE' | 'HARDCORE' | string;
  retryIntervalMinutes?: number;
}

export interface IAlarmRepository {
  findByUserId(userId: string): Promise<AlarmEntity[]> | AlarmEntity[];
  findById(id: string): Promise<AlarmEntity | null> | (AlarmEntity | null);
  create(params: CreateAlarmInput): Promise<AlarmEntity> | AlarmEntity;
}

/**
 * SQLite Implementation of Alarm Repository
 */
export class SqliteAlarmRepository implements IAlarmRepository {
  public findByUserId(userId: string): AlarmEntity[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM alarms WHERE user_id = ? ORDER BY time_of_day ASC').all(userId) as any[];
    return rows.map(this.mapRow);
  }

  public findById(id: string): AlarmEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM alarms WHERE id = ?').get(id) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public create(params: CreateAlarmInput): AlarmEntity {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    const formattedTime = params.timeOfDay.length === 5 ? `${params.timeOfDay}:00` : params.timeOfDay;

    db.prepare(`
      INSERT INTO alarms (id, user_id, task_id, time_of_day, timezone, repeat_days, discipline_mode, retry_interval_minutes, is_enabled, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
    `).run(
      id,
      params.userId,
      params.taskId,
      formattedTime,
      params.timezone || 'UTC',
      JSON.stringify(params.repeatDays),
      params.disciplineMode || 'DISCIPLINE',
      params.retryIntervalMinutes || 5,
      now,
      now
    );

    return this.findById(id)!;
  }

  private mapRow(row: any): AlarmEntity {
    return {
      id: row.id,
      userId: row.user_id,
      taskId: row.task_id,
      timeOfDay: row.time_of_day,
      timezone: row.timezone,
      repeatDays: typeof row.repeat_days === 'string' ? JSON.parse(row.repeat_days || '[]') : (row.repeat_days || []),
      disciplineMode: row.discipline_mode,
      retryIntervalMinutes: Number(row.retry_interval_minutes),
      isEnabled: Boolean(row.is_enabled),
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };
  }
}

/**
 * Prisma PostgreSQL Implementation of Alarm Repository
 */
export class PrismaAlarmRepository implements IAlarmRepository {
  constructor(private readonly db: PrismaClient) {}

  public async findByUserId(userId: string): Promise<AlarmEntity[]> {
    const alarms = await this.db.alarm.findMany({
      where: { userId },
      orderBy: { timeOfDay: 'asc' }
    });
    return alarms.map(this.mapPrismaModel);
  }

  public async findById(id: string): Promise<AlarmEntity | null> {
    const alarm = await this.db.alarm.findUnique({
      where: { id }
    });
    if (!alarm) return null;
    return this.mapPrismaModel(alarm);
  }

  public async create(params: CreateAlarmInput): Promise<AlarmEntity> {
    const formattedTime = params.timeOfDay.length === 5 ? `${params.timeOfDay}:00` : params.timeOfDay;

    const alarm = await this.db.alarm.create({
      data: {
        userId: params.userId,
        taskId: params.taskId,
        timeOfDay: formattedTime,
        timezone: params.timezone || 'UTC',
        repeatDays: JSON.stringify(params.repeatDays),
        disciplineMode: params.disciplineMode || 'DISCIPLINE',
        retryIntervalMinutes: params.retryIntervalMinutes || 5,
        isEnabled: true
      }
    });

    return this.mapPrismaModel(alarm);
  }

  private mapPrismaModel(alarm: any): AlarmEntity {
    return {
      id: alarm.id,
      userId: alarm.userId,
      taskId: alarm.taskId,
      timeOfDay: alarm.timeOfDay,
      timezone: alarm.timezone,
      repeatDays: typeof alarm.repeatDays === 'string' ? JSON.parse(alarm.repeatDays || '[]') : (alarm.repeatDays || []),
      disciplineMode: alarm.disciplineMode,
      retryIntervalMinutes: alarm.retryIntervalMinutes,
      isEnabled: alarm.isEnabled,
      createdAt: alarm.createdAt instanceof Date ? alarm.createdAt.toISOString() : String(alarm.createdAt),
      updatedAt: alarm.updatedAt instanceof Date ? alarm.updatedAt.toISOString() : String(alarm.updatedAt)
    };
  }
}

/**
 * Facade maintaining 100% backward-compatible static API
 */
export class AlarmRepository {
  private static sqliteAdapter = new SqliteAlarmRepository();
  private static prismaAdapter: PrismaAlarmRepository | null = null;

  public static findByUserId(userId: string): AlarmEntity[] {
    return this.sqliteAdapter.findByUserId(userId);
  }

  public static findById(id: string): AlarmEntity | null {
    return this.sqliteAdapter.findById(id);
  }

  public static create(params: CreateAlarmInput): AlarmEntity {
    return this.sqliteAdapter.create(params);
  }
}
