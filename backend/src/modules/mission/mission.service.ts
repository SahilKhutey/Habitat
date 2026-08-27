// Authoritative Mission & Discipline Engine Service
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { MissionStatus, MissionAttemptStatus, MissionEventType, MissionStateMachine } from './domain/mission.rules';

export class MissionService {
  // 1. Create Mission from Alarm or Manual Trigger (Idempotent)
  public static createMission(params: {
    userId: string;
    taskId: string;
    alarmId?: string;
    scheduledAt?: string;
    disciplineMode?: string;
  }) {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    const scheduledAt = params.scheduledAt || now;
    const idempotencyKey = params.alarmId ? `${params.alarmId}_${scheduledAt.substring(0, 16)}` : `manual_${params.taskId}_${now}`;

    // Check Idempotency
    const existing = db.prepare('SELECT id FROM missions WHERE idempotency_key = ?').get(idempotencyKey) as any;
    if (existing) {
      return this.getById(existing.id);
    }

    let validAlarmId: string | null = null;
    if (params.alarmId) {
      const alarmExists = db.prepare('SELECT id FROM alarms WHERE id = ?').get(params.alarmId);
      if (alarmExists) validAlarmId = params.alarmId;
    }

    const missionId = uuidv4();
    const mode = params.disciplineMode || 'DISCIPLINE';

    db.prepare(`
      INSERT INTO missions (id, user_id, alarm_id, task_id, scheduled_at, triggered_at, status, attempt_count, retry_count, discipline_mode, idempotency_key, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, 'ACTIVE', 0, 0, ?, ?, ?, ?)
    `).run(
      missionId,
      params.userId,
      validAlarmId,
      params.taskId,
      scheduledAt,
      now,
      mode,
      idempotencyKey,
      now,
      now
    );

    this.recordEvent(missionId, MissionEventType.MISSION_CREATED, null, MissionStatus.ACTIVE);
    this.recordEvent(missionId, MissionEventType.ALARM_TRIGGERED, null, MissionStatus.ACTIVE);

    return this.getById(missionId);
  }

  // 2. Start Mission
  public static startMission(missionId: string, userId?: string) {
    if (!missionId) throw new Error('MISSION_NOT_FOUND: Mission ID required');
    const db = DatabaseService.getDb();
    const mission = this.getById(missionId, userId);
    if (!mission) throw new Error('MISSION_NOT_FOUND: Mission not found or unauthorized');

    if (mission.status === MissionStatus.IN_PROGRESS) {
      return mission; // Idempotent start
    }

    MissionStateMachine.assertTransition(mission.status as MissionStatus, MissionStatus.IN_PROGRESS);

    const now = new Date().toISOString();
    const nextAttemptNumber = (mission.attemptCount || 0) + 1;
    const attemptId = uuidv4();

    db.prepare(`
      UPDATE missions 
      SET status = 'IN_PROGRESS', started_at = COALESCE(started_at, ?), attempt_count = ?, updated_at = ?
      WHERE id = ?
    `).run(now, nextAttemptNumber, now, missionId);

    db.prepare(`
      INSERT INTO mission_attempts (id, mission_id, attempt_index, started_at, triggered_at, status, siren_volume_level, created_at)
      VALUES (?, ?, ?, ?, ?, 'STARTED', 70, ?)
    `).run(attemptId, missionId, nextAttemptNumber, now, now, now);

    this.recordEvent(missionId, MissionEventType.MISSION_STARTED, mission.status, MissionStatus.IN_PROGRESS, { attemptNumber: nextAttemptNumber });

    return this.getById(missionId);
  }

  // 3. Submit Mission Proof
  public static submitMission(missionId: string, userId?: string, proofData?: any) {
    if (!missionId) throw new Error('MISSION_NOT_FOUND: Mission ID required');
    const db = DatabaseService.getDb();
    const mission = this.getById(missionId, userId);
    if (!mission) throw new Error('MISSION_NOT_FOUND: Mission not found or unauthorized');

    if (mission.status === MissionStatus.VERIFYING) {
      return mission; // Idempotent submit
    }

    MissionStateMachine.assertTransition(mission.status as MissionStatus, MissionStatus.VERIFYING);

    const now = new Date().toISOString();

    db.prepare(`
      UPDATE missions 
      SET status = 'VERIFYING', updated_at = ?
      WHERE id = ?
    `).run(now, missionId);

    db.prepare(`
      UPDATE mission_attempts 
      SET submitted_at = ?, status = 'SUBMITTED'
      WHERE mission_id = ? AND attempt_index = ?
    `).run(now, missionId, mission.attemptCount);

    this.recordEvent(missionId, MissionEventType.PROOF_SUBMITTED, mission.status, MissionStatus.VERIFYING, proofData);

    return this.getById(missionId);
  }

  // 4. Complete Mission (Accept Verification)
  public static completeMission(missionId: string, userId?: string) {
    if (!missionId) throw new Error('MISSION_NOT_FOUND: Mission ID required');
    const db = DatabaseService.getDb();
    const mission = this.getById(missionId, userId);
    if (!mission) throw new Error('MISSION_NOT_FOUND: Mission not found or unauthorized');

    if (mission.status === MissionStatus.COMPLETED) {
      return mission; // Idempotent completion
    }

    const now = new Date();
    const scheduled = new Date(mission.scheduledAt);
    const resistanceSeconds = Math.max(0, Math.floor((now.getTime() - scheduled.getTime()) / 1000));

    db.prepare(`
      UPDATE missions 
      SET status = 'COMPLETED', completed_at = ?, resistance_seconds = ?, next_retry_at = NULL, updated_at = ?
      WHERE id = ?
    `).run(now.toISOString(), resistanceSeconds, now.toISOString(), missionId);

    db.prepare(`
      UPDATE mission_attempts 
      SET resolved_at = ?, status = 'ACCEPTED'
      WHERE mission_id = ? AND status != 'ACCEPTED'
    `).run(now.toISOString(), missionId);

    // Cancel pending retry alarms
    db.prepare("UPDATE mission_attempts SET status = 'CANCELLED' WHERE mission_id = ? AND status = 'SCHEDULED'").run(missionId);

    this.recordEvent(missionId, MissionEventType.MISSION_COMPLETED, mission.status, MissionStatus.COMPLETED, { resistanceSeconds });

    return this.getById(missionId);
  }

  // 5. Retry Mission (Reject Verification & Schedule +5 Min Alarm)
  public static retryMission(missionId: string, failureReason: string = 'Proof rejected', userId?: string) {
    if (!missionId) throw new Error('MISSION_NOT_FOUND: Mission ID required');
    const db = DatabaseService.getDb();
    const mission = this.getById(missionId, userId);
    if (!mission) throw new Error('MISSION_NOT_FOUND: Mission not found or unauthorized');

    if (mission.status === MissionStatus.COMPLETED) {
      throw new Error('MISSION_INVALID_STATE: Cannot retry completed mission');
    }

    const now = new Date();
    const nextRetryDate = new Date(now.getTime() + 5 * 60 * 1000);
    const newRetryCount = (mission.retryCount || 0) + 1;

    db.prepare(`
      UPDATE missions 
      SET status = 'RETRY', retry_count = ?, next_retry_at = ?, updated_at = ?
      WHERE id = ?
    `).run(newRetryCount, nextRetryDate.toISOString(), now.toISOString(), missionId);

    db.prepare(`
      UPDATE mission_attempts 
      SET resolved_at = ?, status = 'REJECTED', failure_reason = ?
      WHERE mission_id = ? AND status IN ('STARTED', 'SUBMITTED')
    `).run(now.toISOString(), failureReason, missionId);

    this.recordEvent(missionId, MissionEventType.VERIFICATION_FAILED, mission.status, MissionStatus.RETRY, { failureReason });
    this.recordEvent(missionId, MissionEventType.MISSION_RETRY_SCHEDULED, MissionStatus.RETRY, MissionStatus.RETRY, { nextRetryAt: nextRetryDate.toISOString() });

    return this.getById(missionId);
  }

  // 6. Cancel Mission
  public static cancelMission(missionId: string, reason?: string, userId?: string) {
    if (!missionId) throw new Error('MISSION_NOT_FOUND: Mission ID required');
    const db = DatabaseService.getDb();
    const mission = this.getById(missionId, userId);
    if (!mission) throw new Error('MISSION_NOT_FOUND: Mission not found or unauthorized');

    if (mission.status === MissionStatus.COMPLETED) {
      throw new Error('MISSION_INVALID_STATE: Cannot cancel completed mission');
    }

    const now = new Date().toISOString();

    db.prepare(`
      UPDATE missions 
      SET status = 'CANCELLED', cancelled_at = ?, next_retry_at = NULL, updated_at = ?
      WHERE id = ?
    `).run(now, now, missionId);

    this.recordEvent(missionId, MissionEventType.MISSION_CANCELLED, mission.status, MissionStatus.CANCELLED, { reason });

    return this.getById(missionId);
  }

  // 7. Get Current Active Mission for User
  public static getCurrentMission(userId: string) {
    const db = DatabaseService.getDb();
    const row = db.prepare(`
      SELECT 
        m.*,
        t.title as task_title, t.name as task_name, t.description as task_description,
        t.instructions as task_instructions, t.category as task_category,
        t.proof_type as task_proof_type, t.base_xp as task_base_xp, t.icon_name as task_icon_name
      FROM missions m
      JOIN tasks t ON m.task_id = t.id
      WHERE m.user_id = ? AND m.status IN ('ACTIVE', 'IN_PROGRESS', 'VERIFYING', 'RETRY')
      ORDER BY m.created_at DESC
      LIMIT 1
    `).get(userId) as any;

    if (!row) return null;
    return this.mapMission(row);
  }

  // 8. Get Single Mission by ID
  public static getById(id: string, userId?: string) {
    if (!id) return null;
    const db = DatabaseService.getDb();
    let query = `
      SELECT 
        m.*,
        t.title as task_title, t.name as task_name, t.description as task_description,
        t.instructions as task_instructions, t.category as task_category,
        t.proof_type as task_proof_type, t.base_xp as task_base_xp, t.icon_name as task_icon_name
      FROM missions m
      JOIN tasks t ON m.task_id = t.id
      WHERE m.id = ?
    `;
    const params: any[] = [id];

    if (userId) {
      query += ' AND m.user_id = ?';
      params.push(userId);
    }

    const row = db.prepare(query).get(...params) as any;
    if (!row) return null;
    return this.mapMission(row);
  }

  // 9. Get Mission Events Audit History
  public static getEvents(missionId: string) {
    if (!missionId) return [];
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM mission_events WHERE mission_id = ? ORDER BY created_at ASC').all(missionId) as any[];

    return rows.map((r) => ({
      id: r.id,
      missionId: r.mission_id,
      type: r.type,
      fromStatus: r.from_status,
      toStatus: r.to_status,
      metadata: JSON.parse(r.metadata || '{}'),
      createdAt: r.created_at
    }));
  }

  private static recordEvent(missionId: string, type: MissionEventType, fromStatus: string | null, toStatus: string, metadata?: any) {
    const db = DatabaseService.getDb();
    db.prepare(`
      INSERT INTO mission_events (id, mission_id, type, from_status, to_status, metadata, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(
      uuidv4(),
      missionId,
      type,
      fromStatus,
      toStatus,
      JSON.stringify(metadata || {}),
      new Date().toISOString()
    );
  }

  private static mapMission(row: any) {
    let parsedInstructions = row.task_instructions;
    try {
      if (row.task_instructions && typeof row.task_instructions === 'string' && row.task_instructions.startsWith('[')) {
        parsedInstructions = JSON.parse(row.task_instructions);
      }
    } catch {
      // keep string
    }

    return {
      id: row.id,
      userId: row.user_id,
      alarmId: row.alarm_id,
      taskId: row.task_id,
      task: {
        id: row.task_id,
        title: row.task_title || row.task_name,
        name: row.task_name || row.task_title,
        description: row.task_description,
        instructions: parsedInstructions,
        category: row.task_category,
        proofType: row.task_proof_type,
        baseXp: row.task_base_xp,
        iconName: row.task_icon_name
      },
      status: row.status,
      scheduledAt: row.scheduled_at,
      startedAt: row.started_at,
      completedAt: row.completed_at,
      cancelledAt: row.cancelled_at,
      expiredAt: row.expired_at,
      attemptCount: row.attempt_count || 0,
      retryCount: row.retry_count || 0,
      nextRetryAt: row.next_retry_at,
      resistanceSeconds: row.resistance_seconds,
      disciplineMode: row.discipline_mode,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };
  }
}
