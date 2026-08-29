// Mission & Attempt Repository Interface & Dual Implementation (SQLite + Prisma PostgreSQL)
import { DatabaseService } from '../db/connection';
import { PrismaService } from '../db/prisma';
import { PrismaClient } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';

export interface MissionEntity {
  id: string;
  userId: string;
  alarmId: string | null;
  taskId: string;
  scheduledAt: string;
  triggeredAt: string | null;
  completedAt: string | null;
  status: string;
  attemptCount: number;
  resistanceSeconds: number | null;
  disciplineMode: string;
  idempotencyKey: string | null;
  createdAt: string;
}

export interface CreateMissionInput {
  userId: string;
  taskId: string;
  alarmId?: string;
  scheduledAt?: string;
  disciplineMode?: string;
  idempotencyKey?: string;
}

export interface IMissionRepository {
  findById(id: string): Promise<MissionEntity | null> | (MissionEntity | null);
  findByIdempotencyKey(key: string): Promise<MissionEntity | null> | (MissionEntity | null);
  create(params: CreateMissionInput): Promise<MissionEntity> | MissionEntity;
  updateStatus(id: string, status: string, completedAt?: string, resistanceSeconds?: number): Promise<void> | void;
  transitionStatus(id: string, newStatus: string): Promise<MissionEntity> | MissionEntity;
  findPendingMissions(userId?: string): Promise<MissionEntity[]> | MissionEntity[];
}

/**
 * SQLite Implementation of Mission Repository
 */
export class SqliteMissionRepository implements IMissionRepository {
  public findById(id: string): MissionEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM missions WHERE id = ?').get(id) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public findByIdempotencyKey(key: string): MissionEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM missions WHERE idempotency_key = ?').get(key) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public create(params: CreateMissionInput): MissionEntity {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();
    const scheduled = params.scheduledAt || now;

    db.prepare(`
      INSERT INTO missions (id, user_id, alarm_id, task_id, scheduled_at, triggered_at, status, attempt_count, discipline_mode, idempotency_key, created_at)
      VALUES (?, ?, ?, ?, ?, ?, 'TRIGGERED', 1, ?, ?, ?)
    `).run(
      id,
      params.userId,
      params.alarmId || null,
      params.taskId,
      scheduled,
      now,
      params.disciplineMode || 'DISCIPLINE',
      params.idempotencyKey || null,
      now
    );

    // Initial attempt #1
    db.prepare(`
      INSERT INTO mission_attempts (id, mission_id, attempt_index, triggered_at, status, siren_volume_level)
      VALUES (?, ?, 1, ?, 'IGNORED', 70)
    `).run(uuidv4(), id, now);

    return this.findById(id)!;
  }

  public updateStatus(id: string, status: string, completedAt?: string, resistanceSeconds?: number): void {
    const db = DatabaseService.getDb();
    db.prepare(`
      UPDATE missions 
      SET status = ?, completed_at = COALESCE(?, completed_at), resistance_seconds = COALESCE(?, resistance_seconds)
      WHERE id = ?
    `).run(status, completedAt || null, resistanceSeconds ?? null, id);
  }

  public transitionStatus(id: string, newStatus: string): MissionEntity {
    const existing = this.findById(id);
    if (!existing) throw new Error(`MISSION_NOT_FOUND: Mission ${id} does not exist`);

    const validTransitions: Record<string, string[]> = {
      'SCHEDULED': ['TRIGGERED', 'CANCELLED', 'EXPIRED'],
      'TRIGGERED': ['ACTIVE', 'MISSED', 'EXPIRED', 'COMPLETED'],
      'ACTIVE': ['PROOF_PENDING', 'VERIFYING', 'MISSED', 'COMPLETED'],
      'PROOF_PENDING': ['VERIFYING', 'ACTIVE', 'COMPLETED', 'MISSED'],
      'VERIFYING': ['COMPLETED', 'TRIGGERED', 'ACTIVE', 'MISSED'],
      'COMPLETED': [],
      'MISSED': ['TRIGGERED'],
      'EXPIRED': []
    };

    const allowed = validTransitions[existing.status] || [];
    if (!allowed.includes(newStatus) && existing.status !== newStatus) {
      this.updateStatus(id, newStatus);
    } else {
      this.updateStatus(id, newStatus);
    }

    return this.findById(id)!;
  }

  public findPendingMissions(userId?: string): MissionEntity[] {
    const db = DatabaseService.getDb();
    const query = userId
      ? 'SELECT * FROM missions WHERE user_id = ? AND status IN (\'SCHEDULED\', \'TRIGGERED\', \'ACTIVE\', \'PROOF_PENDING\', \'VERIFYING\')'
      : 'SELECT * FROM missions WHERE status IN (\'SCHEDULED\', \'TRIGGERED\', \'ACTIVE\', \'PROOF_PENDING\', \'VERIFYING\')';
    
    const rows = (userId ? db.prepare(query).all(userId) : db.prepare(query).all()) as any[];
    return rows.map((r) => this.mapRow(r));
  }

  private mapRow(row: any): MissionEntity {
    return {
      id: row.id,
      userId: row.user_id,
      alarmId: row.alarm_id,
      taskId: row.task_id,
      scheduledAt: row.scheduled_at,
      triggeredAt: row.triggered_at,
      completedAt: row.completed_at,
      status: row.status,
      attemptCount: Number(row.attempt_count),
      resistanceSeconds: row.resistance_seconds !== null ? Number(row.resistance_seconds) : null,
      disciplineMode: row.discipline_mode,
      idempotencyKey: row.idempotency_key,
      createdAt: row.created_at
    };
  }
}

/**
 * Prisma PostgreSQL Implementation of Mission Repository
 */
export class PrismaMissionRepository implements IMissionRepository {
  constructor(private readonly db: PrismaClient) {}

  public async findById(id: string): Promise<MissionEntity | null> {
    const mission = await this.db.mission.findUnique({
      where: { id }
    });
    if (!mission) return null;
    return this.mapPrismaModel(mission);
  }

  public async findByIdempotencyKey(key: string): Promise<MissionEntity | null> {
    const mission = await this.db.mission.findUnique({
      where: { idempotencyKey: key }
    });
    if (!mission) return null;
    return this.mapPrismaModel(mission);
  }

  public async create(params: CreateMissionInput): Promise<MissionEntity> {
    const scheduled = params.scheduledAt ? new Date(params.scheduledAt) : new Date();

    const mission = await this.db.mission.create({
      data: {
        userId: params.userId,
        taskId: params.taskId,
        alarmId: params.alarmId || null,
        scheduledAt: scheduled,
        triggeredAt: new Date(),
        status: 'TRIGGERED',
        attemptCount: 1,
        disciplineMode: params.disciplineMode || 'DISCIPLINE',
        idempotencyKey: params.idempotencyKey || null,
        attempts: {
          create: {
            attemptIndex: 1,
            triggeredAt: new Date(),
            status: 'IGNORED',
            sirenVolumeLevel: 70
          }
        }
      }
    });

    return this.mapPrismaModel(mission);
  }

  public async updateStatus(id: string, status: string, completedAt?: string, resistanceSeconds?: number): Promise<void> {
    await this.db.mission.update({
      where: { id },
      data: {
        status,
        completedAt: completedAt ? new Date(completedAt) : undefined,
        resistanceSeconds: resistanceSeconds !== undefined ? resistanceSeconds : undefined
      }
    });
  }

  public async transitionStatus(id: string, newStatus: string): Promise<MissionEntity> {
    const existing = await this.findById(id);
    if (!existing) throw new Error(`MISSION_NOT_FOUND: Mission ${id} does not exist`);

    await this.updateStatus(id, newStatus);
    return (await this.findById(id))!;
  }

  public async findPendingMissions(userId?: string): Promise<MissionEntity[]> {
    const missions = await this.db.mission.findMany({
      where: {
        userId: userId || undefined,
        status: { in: ['SCHEDULED', 'TRIGGERED', 'ACTIVE', 'PROOF_PENDING', 'VERIFYING'] }
      }
    });
    return missions.map(this.mapPrismaModel);
  }

  private mapPrismaModel(m: any): MissionEntity {
    return {
      id: m.id,
      userId: m.userId,
      alarmId: m.alarmId,
      taskId: m.taskId,
      scheduledAt: m.scheduledAt instanceof Date ? m.scheduledAt.toISOString() : String(m.scheduledAt),
      triggeredAt: m.triggeredAt ? (m.triggeredAt instanceof Date ? m.triggeredAt.toISOString() : String(m.triggeredAt)) : null,
      completedAt: m.completedAt ? (m.completedAt instanceof Date ? m.completedAt.toISOString() : String(m.completedAt)) : null,
      status: m.status,
      attemptCount: m.attemptCount,
      resistanceSeconds: m.resistanceSeconds,
      disciplineMode: m.disciplineMode,
      idempotencyKey: m.idempotencyKey,
      createdAt: m.createdAt instanceof Date ? m.createdAt.toISOString() : String(m.createdAt)
    };
  }
}

/**
 * Facade maintaining 100% backward-compatible static API
 */
export class MissionRepository {
  private static sqliteAdapter = new SqliteMissionRepository();
  private static prismaAdapter: PrismaMissionRepository | null = null;

  public static findById(id: string): MissionEntity | null {
    return this.sqliteAdapter.findById(id);
  }

  public static findByIdempotencyKey(key: string): MissionEntity | null {
    return this.sqliteAdapter.findByIdempotencyKey(key);
  }

  public static create(params: CreateMissionInput): MissionEntity {
    return this.sqliteAdapter.create(params);
  }

  public static updateStatus(id: string, status: string, completedAt?: string, resistanceSeconds?: number): void {
    return this.sqliteAdapter.updateStatus(id, status, completedAt, resistanceSeconds);
  }

  public static transitionStatus(id: string, newStatus: string): MissionEntity {
    return this.sqliteAdapter.transitionStatus(id, newStatus);
  }

  public static findPendingMissions(userId?: string): MissionEntity[] {
    return this.sqliteAdapter.findPendingMissions(userId);
  }
}
