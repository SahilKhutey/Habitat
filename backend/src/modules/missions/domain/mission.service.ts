// Production Mission Service orchestrating real lifecycle, attempts, and verification
import {
  IMissionRepository,
  MissionEntity,
  CreateMissionInput
} from '../../../repositories/mission.repository';
import { DatabaseFactory } from '../../../db/database.factory';
import {
  MissionLifecycleService,
  ValidMissionStatus
} from '../mission-lifecycle.service';
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';

export interface CompleteMissionParams {
  missionId: string;
  userId: string;
  resistanceSeconds: number;
  baseXp: number;
  idempotencyKey?: string;
}

export class MissionService {
  constructor(private readonly repository?: IMissionRepository) {}

  private getRepo(): IMissionRepository {
    if (this.repository) return this.repository;
    return DatabaseFactory.getMissionRepository();
  }

  public async createMission(params: CreateMissionInput): Promise<MissionEntity> {
    if (!params.userId || !params.taskId) {
      throw new Error('INVALID_MISSION: userId and taskId are required.');
    }
    return this.getRepo().create(params);
  }

  public async getMission(id: string): Promise<MissionEntity | null> {
    return this.getRepo().findById(id);
  }

  public async startMission(missionId: string): Promise<MissionEntity> {
    const mission = await this.getMission(missionId);
    if (!mission) throw new Error(`MISSION_NOT_FOUND: Mission ${missionId} does not exist.`);

    if (mission.status === 'ACTIVE') {
      return mission;
    }

    if (mission.status === 'SCHEDULED' || mission.status === 'TRIGGERED') {
      MissionLifecycleService.transitionMission(missionId, 'ACTIVE');
      return (await this.getMission(missionId))!;
    }

    throw new Error(
      `INVALID_STATE_TRANSITION: Cannot start mission in status "${mission.status}".`
    );
  }

  public async submitProof(missionId: string, proofId?: string): Promise<MissionEntity> {
    const mission = await this.getMission(missionId);
    if (!mission) throw new Error(`MISSION_NOT_FOUND: Mission ${missionId} does not exist.`);

    if (mission.status === 'TRIGGERED') {
      MissionLifecycleService.transitionMission(missionId, 'ACTIVE');
    }

    MissionLifecycleService.transitionMission(missionId, 'SUBMITTED');
    MissionLifecycleService.transitionMission(missionId, 'VERIFYING');

    return (await this.getMission(missionId))!;
  }

  public completeMission(params: CompleteMissionParams): {
    mission: MissionEntity;
    xpAwarded: number;
    streak: any;
  } {
    return MissionLifecycleService.completeMissionAtomic(params);
  }

  public async retryMission(missionId: string, reason: string): Promise<MissionEntity> {
    const mission = await this.getMission(missionId);
    if (!mission) throw new Error(`MISSION_NOT_FOUND: Mission ${missionId} does not exist.`);

    const db = DatabaseService.getDb();
    const nextAttemptIndex = (mission.attemptCount || 1) + 1;
    const now = new Date().toISOString();

    // Log the failed attempt in mission_attempts
    db.prepare(`
      INSERT INTO mission_attempts (id, mission_id, attempt_index, triggered_at, resolved_at, status, siren_volume_level, failure_reason, created_at)
      VALUES (?, ?, ?, ?, ?, 'FAILED', 85, ?, ?)
    `).run(uuidv4(), missionId, nextAttemptIndex - 1, now, now, reason, now);

    // Increment attempt count on mission and reset to ACTIVE for retry
    db.prepare(`
      UPDATE missions 
      SET attempt_count = ?, status = 'ACTIVE', updated_at = ?
      WHERE id = ?
    `).run(nextAttemptIndex, now, missionId);

    return (await this.getMission(missionId))!;
  }

  public async getActiveMissions(userId?: string): Promise<MissionEntity[]> {
    return this.getRepo().findPendingMissions(userId);
  }

  public async getMissionHistory(userId: string, limit?: number): Promise<MissionEntity[]> {
    return this.getRepo().findByUserId(userId, limit);
  }
}
