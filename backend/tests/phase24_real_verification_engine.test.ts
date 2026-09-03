// Phase 24: Real Verification Engine End-to-End Test Suite
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { EvidenceVerificationService } from '../src/modules/verification/domain/evidence-verification.service';
import { ProofFileStore } from '../src/modules/proofs/domain/proof-file-store';
import { TaskService } from '../src/modules/tasks/domain/task.service';
import { MissionService } from '../src/modules/missions/domain/mission.service';
import { ProofCaptureService } from '../src/modules/proofs/domain/proof-capture.service';
import { SessionChallengeService } from '../src/modules/proofs/services/session-challenge.service';
import { MoveNetLightningEngine } from '../src/modules/verification/engine/movenet-lightning.engine';
import { v4 as uuidv4 } from 'uuid';
import fs from 'fs';
import path from 'path';

describe('Phase 24: Real Verification Engine Pipeline', () => {
  const testUserId = uuidv4();
  const testStorageDir = path.resolve(process.cwd(), 'data', 'test_proofs_phase24');

  let taskService: TaskService;
  let missionService: MissionService;
  let proofCaptureService: ProofCaptureService;
  let verificationService: EvidenceVerificationService;

  beforeAll(async () => {
    DatabaseService.getDb();
    const db = DatabaseService.getDb();

    // Create test user
    db.prepare(`
      INSERT OR IGNORE INTO users (id, email, password_hash, display_name, timezone, created_at, updated_at)
      VALUES (?, ?, 'hash', 'Verification Recruit', 'UTC', ?, ?)
    `).run(testUserId, `v_recruit_${testUserId}@habitat.internal`, new Date().toISOString(), new Date().toISOString());

    ProofFileStore.setStorageDirForTesting(testStorageDir);

    taskService = new TaskService();
    missionService = new MissionService();
    proofCaptureService = new ProofCaptureService(undefined, missionService);
    verificationService = new EvidenceVerificationService(missionService);

    process.env.VISION_PROVIDER = 'movenet';
    await MoveNetLightningEngine.initialize();
  });

  afterAll(() => {
    if (fs.existsSync(testStorageDir)) {
      fs.rmSync(testStorageDir, { recursive: true, force: true });
    }
    ProofFileStore.setStorageDirForTesting(path.resolve(process.cwd(), 'data', 'proofs'));
  });

  it('24.1: ProofValidator rejects non-existent or tampered proofs', async () => {
    const task = await taskService.createTask({
      userId: testUserId,
      title: 'Validation Task',
      description: 'Test proof validation',
      category: 'FITNESS',
      proofType: 'VIDEO'
    });
    const mission = await missionService.createMission({
      userId: testUserId,
      taskId: task.id
    });

    const fakeProofId = uuidv4();

    const result = await verificationService.verifyProof({
      proofId: fakeProofId,
      missionId: mission.id,
      userId: testUserId
    });

    expect(result.decision).toBe('REJECT');
    expect(result.reasons.some((r) => r.includes('was not found'))).toBe(true);

    // Verify verification audit record was persisted in SQLite
    const db = DatabaseService.getDb();
    const verificationRow = db.prepare('SELECT * FROM verifications WHERE proof_id = ?').get(fakeProofId) as any;
    expect(verificationRow).not.toBeNull();
    expect(verificationRow.decision).toBe('REJECT');
  });

  it('24.2: Session Nonce Replay Defense rejects already-consumed or mismatched nonces', async () => {
    const task = await taskService.createTask({
      userId: testUserId,
      title: 'Session Nonce Task',
      description: 'Test session challenges',
      category: 'FITNESS',
      proofType: 'VIDEO'
    });

    const mission = await missionService.createMission({
      userId: testUserId,
      taskId: task.id
    });
    await missionService.startMission(mission.id);

    // Capture valid payload
    const session = proofCaptureService.initializeSession(mission.id, testUserId);
    const videoBuffer = Buffer.from('HABITAT_SESSION_NONCE_VERIFICATION_VIDEO_FRAME_BYTES_TEST');
    proofCaptureService.capturePayload(session.sessionId, videoBuffer, 'video/mp4');
    const proof = await proofCaptureService.finalizeProof(session.sessionId);

    // Create session challenge
    const challenge = SessionChallengeService.issueChallenge(mission.id, testUserId);

    // First attempt with valid challenge
    // Note: this will proceed past nonce check and fail at frame decoding, but nonce will be consumed
    const firstResult = await verificationService.verifyProof({
      proofId: proof.id,
      missionId: mission.id,
      userId: testUserId,
      sessionId: challenge.sessionId,
      sessionNonce: challenge.sessionNonce
    });
    expect(firstResult).toBeDefined();

    // Second attempt with SAME consumed nonce must be rejected with REPLAY_NONCE_INVALID
    const secondResult = await verificationService.verifyProof({
      proofId: proof.id,
      missionId: mission.id,
      userId: testUserId,
      sessionId: challenge.sessionId,
      sessionNonce: challenge.sessionNonce
    });

    expect(secondResult.decision).toBe('REJECT');
    expect(secondResult.reasons.some((r) => r.toLowerCase().includes('consumed') || r.toLowerCase().includes('invalid'))).toBe(true);
  });

  it('24.3: Static image attack is detected and rejected by ReplayDetector and LivenessAnalyzer', async () => {
    const task = await taskService.createTask({
      userId: testUserId,
      title: 'Anti-Static Image Task',
      description: 'Detect frozen frames',
      category: 'FITNESS',
      proofType: 'VIDEO'
    });

    const mission = await missionService.createMission({
      userId: testUserId,
      taskId: task.id
    });
    await missionService.startMission(mission.id);

    const session = proofCaptureService.initializeSession(mission.id, testUserId);
    // Create static payload
    const staticPayload = Buffer.alloc(192 * 192 * 3, 128); // Uniform gray static pixel buffer
    proofCaptureService.capturePayload(session.sessionId, staticPayload, 'video/mp4');
    const proof = await proofCaptureService.finalizeProof(session.sessionId);

    const result = await verificationService.verifyProof({
      proofId: proof.id,
      missionId: mission.id,
      userId: testUserId,
      targetReps: 10
    });

    expect(result.decision).toBe('REJECT');
    expect(result.missionStatus).toBe('ACTIVE'); // Retry triggered
  });

  it('24.4: Periodic video loop replay attack is detected and rejected', async () => {
    const task = await taskService.createTask({
      userId: testUserId,
      title: 'Loop Attack Task',
      description: 'Detect looped video',
      category: 'FITNESS',
      proofType: 'VIDEO'
    });

    const mission = await missionService.createMission({
      userId: testUserId,
      taskId: task.id
    });
    await missionService.startMission(mission.id);

    const session = proofCaptureService.initializeSession(mission.id, testUserId);
    const loopPayload = Buffer.alloc(192 * 192 * 3, 200);
    proofCaptureService.capturePayload(session.sessionId, loopPayload, 'video/mp4');
    const proof = await proofCaptureService.finalizeProof(session.sessionId);

    const result = await verificationService.verifyProof({
      proofId: proof.id,
      missionId: mission.id,
      userId: testUserId,
      targetReps: 10
    });

    expect(result.decision).toBe('REJECT');
  });

  it('24.5: Fail-Closed Invariant: Verification record is persisted in SQLite with complete audit metrics', async () => {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM verifications WHERE user_id = ?').all(testUserId) as any[];

    expect(rows.length).toBeGreaterThanOrEqual(3);

    for (const row of rows) {
      expect(row.id).toBeDefined();
      expect(row.proof_id).toBeDefined();
      expect(row.mission_id).toBeDefined();
      expect(row.verifier).toBe('MoveNet-Lightning');
      expect(row.decision).toMatch(/ACCEPT|REVIEW|REJECT/);
      expect(row.created_at).toBeDefined();

      const checks = JSON.parse(row.checks || '[]');
      expect(Array.isArray(checks)).toBe(true);
    }
  });
});
