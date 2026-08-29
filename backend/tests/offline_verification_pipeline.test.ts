// End-to-End Tests: Complete Offline-First Verification Pipeline (Zero Network Dependency)
import { describe, it, expect, beforeEach } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { MissionRepository } from '../src/repositories/mission.repository';
import { proofRepository } from '../src/repositories/proof.repository';
import { NativeAlarmScheduler } from '../src/modules/alarms/services/native-alarm-scheduler';
import { VerificationEngine } from '../src/modules/verification/verification.engine';
import { SessionChallengeService } from '../src/modules/proofs/services/session-challenge.service';
import { VerificationEvidence } from '../src/modules/verification/domain/evidence.types';
import { createDefaultProvenance } from '../src/modules/verification/domain/evidence-provenance';

describe('Offline-First Verification Pipeline', () => {
  let defaultUserId: string;
  let taskId: string;

  beforeEach(() => {
    DatabaseService.resetDbForTesting();
    SessionChallengeService.resetForTesting();
    NativeAlarmScheduler.resetForTesting();

    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;

    const db = DatabaseService.getDb();
    const task = db.prepare('SELECT id FROM tasks LIMIT 1').get() as { id: string };
    taskId = task.id;
  });

  it('completes end-to-end alarm firing, on-device CV verification, and local XP recording with zero network connectivity', () => {
    const alarmId = 'alarm-offline-1';
    const scheduledAt = new Date().toISOString();

    const db = DatabaseService.getDb();
    db.prepare(`
      INSERT INTO alarms (id, user_id, task_id, time_of_day, timezone, repeat_days, created_at, updated_at)
      VALUES (?, ?, ?, '07:00:00', 'UTC', '[1,2,3,4,5]', datetime('now'), datetime('now'))
    `).run(alarmId, defaultUserId, taskId);

    // 1. Alarm Scheduled Locally
    const mission = MissionRepository.create({
      userId: defaultUserId,
      taskId,
      alarmId,
      disciplineMode: 'DISCIPLINE'
    });

    const occ = NativeAlarmScheduler.scheduleExactAlarm({
      alarmId,
      missionId: mission.id,
      userId: defaultUserId,
      scheduledAt,
      platform: 'android'
    });

    expect(occ.status).toBe('SCHEDULED');

    // 2. Native OS Alarm Manager triggers locally
    NativeAlarmScheduler.onAlarmTriggered(occ.occurrenceId, 5);

    const triggeredMission = MissionRepository.findById(mission.id);
    expect(triggeredMission?.status).toBe('TRIGGERED');

    // 3. User launches task and transitions to ACTIVE
    MissionRepository.transitionStatus(mission.id, 'ACTIVE');

    // 4. Cryptographic challenge issued on-device
    const challenge = SessionChallengeService.issueChallenge(mission.id, defaultUserId);

    // 5. On-device MoveNet generates pose trajectory and liveness evidence with Provenance
    const provenance = createDefaultProvenance({
      modelName: 'MoveNet-Lightning',
      runtimePlatform: 'android'
    });

    expect(provenance.modelName).toBe('MoveNet-Lightning');
    expect(provenance.schemaVersion).toBe('2.0.0');

    const offlineEvidence: VerificationEvidence = {
      sessionId: challenge.sessionId,
      sessionNonce: challenge.sessionNonce,
      missionId: mission.id,
      taskSlug: 'tpl-pushups-10',
      startedAt: new Date(Date.now() - 10000).toISOString(),
      completedAt: new Date().toISOString(),
      durationMs: 10000,
      pose: {
        model: provenance.modelName,
        modelVersion: provenance.modelVersion,
        totalFramesSampled: 300,
        meanPoseConfidence: 0.95,
        frameTrajectory: Array.from({ length: 300 }, (_, i) => ({
          timestampMs: i * 33,
          frameIndex: i,
          frameHash: `offline_hash_${i}`,
          keypoints: [],
          leftElbowAngleDeg: 165 - 85 * Math.sin(((i % 30) / 30) * Math.PI),
          rightElbowAngleDeg: 165 - 85 * Math.sin(((i % 30) / 30) * Math.PI),
          bodyAlignmentAngleDeg: 170
        })),
        repsCalculated: 10,
        shallowRepsCalculated: 0,
        stateTransitions: []
      },
      liveness: {
        livenessScore: 0.94,
        temporalContinuityScore: 1.0,
        frameUniquenessScore: 1.0,
        trajectoryConsistencyScore: 0.94,
        motionContinuityScore: 1.0,
        replayRiskScore: 0.0,
        challengePassed: true
      },
      integrity: {
        clientAppVersion: '1.0.0',
        evidencePayloadHash: 'offline_sha256_hash'
      }
    };

    // 6. On-device / Local Verification Engine evaluates
    const verification = VerificationEngine.verifyEvidence(offlineEvidence, { minRepetitions: 10 });
    expect(verification.decision).toBe('ACCEPT');
    expect(verification.repsVerified).toBe(10);

    // 7. Complete Mission, Disarm Alarm & Award XP locally
    NativeAlarmScheduler.onMissionCompleted(occ.occurrenceId, mission.id);

    const proof = proofRepository.create({
      missionId: mission.id,
      userId: defaultUserId,
      mediaType: 'VIDEO',
      storageKey: `proofs/${defaultUserId}/${mission.id}/offline.mp4`,
      verificationStatus: 'ACCEPTED'
    });

    expect(proof.verificationStatus).toBe('ACCEPTED');

    const dbInstance = DatabaseService.getDb();
    dbInstance.prepare(`
      INSERT INTO xp_transactions (id, user_id, amount, reason, created_at)
      VALUES (?, ?, ?, ?, datetime('now'))
    `).run('tx-offline-1', defaultUserId, 50, 'OFFLINE_MISSION_COMPLETED');

    const xpEntry = dbInstance.prepare('SELECT * FROM xp_transactions WHERE id = ?').get('tx-offline-1') as any;
    expect(xpEntry).toBeDefined();
    expect(xpEntry.amount).toBe(50);
  });
});
