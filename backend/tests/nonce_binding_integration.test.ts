// Integration Test: Session Challenge Nonce Binding in verifyWithRealVision
// Proves that the real sessionId/nonce stored at upload time is used for verification,
// enabling genuine replay-attack prevention and cross-session mismatch detection.
import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { SessionChallengeService } from '../src/modules/proofs/services/session-challenge.service';
import { ProofsService } from '../src/modules/proofs/proofs.controller';
import { MissionsService } from '../src/modules/missions/missions.controller';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { StorageFactory } from '../src/modules/storage/storage.factory';
import { MoveNetLightningEngine } from '../src/modules/verification/engine/movenet-lightning.engine';

const INFERENCE_TIMEOUT = 30_000;

describe('Session Challenge Nonce Binding: verifyWithRealVision', () => {
  let defaultUserId: string;
  let pushupTask: { id: string; slug: string };

  const originalVisionProvider = process.env.VISION_PROVIDER;

  beforeAll(async () => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;

    const tasks = TasksService.getAll();
    pushupTask = tasks.find((t) => t.slug === 'pushups') || tasks[0];

    process.env.VISION_PROVIDER = 'movenet';
    await MoveNetLightningEngine.initialize();
  }, INFERENCE_TIMEOUT);

  afterAll(() => {
    process.env.VISION_PROVIDER = originalVisionProvider;
  });

  beforeEach(() => {
    SessionChallengeService.resetForTesting();
  });

  /** Helper: creates a proof with optional session binding and saves a dummy media buffer */
  async function createBoundProof(options?: {
    sessionId?: string;
    sessionNonce?: string;
  }) {
    const mission = MissionsService.triggerMission({
      userId: defaultUserId,
      taskId: pushupTask.id,
      disciplineMode: 'DISCIPLINE'
    });
    expect(mission).toBeDefined();

    const upload = ProofsService.createUploadSession({
      userId: defaultUserId,
      missionId: mission!.id,
      type: 'PHOTO',
      mimeType: 'image/jpeg',
      sizeBytes: 192 * 192 * 3,
      sessionId: options?.sessionId,
      sessionNonce: options?.sessionNonce
    });

    const storage = StorageFactory.getProvider();
    await storage.saveBuffer!(upload.objectKey, Buffer.alloc(192 * 192 * 3, 50), 'image/jpeg');

    return { upload, missionId: mission!.id };
  }

  it('N1: proof without challenge binding runs with nonce skipped and nonceValidated=false', async () => {
    const { upload } = await createBoundProof(); // no sessionId/sessionNonce

    const result = await ProofsService.verifyWithRealVision(upload.proofId, {
      minRepetitions: 0,
      // No skipNonceValidation override — should auto-detect no binding and skip
    });

    expect(result.proofId).toBe(upload.proofId);
    expect(result.nonceValidated).toBe(false);
    expect(['ACCEPT', 'REVIEW', 'REJECT']).toContain(result.decision);
    // No INVALID_OR_REPLAYED_SESSION_NONCE flag since nonce was skipped
    expect(result.flags).not.toContain('INVALID_OR_REPLAYED_SESSION_NONCE');
  }, INFERENCE_TIMEOUT);

  it('N2: proof bound to a valid challenge passes nonce validation and nonceValidated=true', async () => {
    const challenge = SessionChallengeService.issueChallenge(
      'test-mission-1',
      defaultUserId
    );

    const { upload } = await createBoundProof({
      sessionId: challenge.sessionId,
      sessionNonce: challenge.sessionNonce
    });

    const result = await ProofsService.verifyWithRealVision(upload.proofId, {
      minRepetitions: 0
    });

    expect(result.nonceValidated).toBe(true);
    expect(result.flags).not.toContain('INVALID_OR_REPLAYED_SESSION_NONCE');
    expect(['ACCEPT', 'REVIEW', 'REJECT']).toContain(result.decision);
  }, INFERENCE_TIMEOUT);

  it('N3: replay attack — consuming same nonce twice is REJECTED on second call', async () => {
    const challenge = SessionChallengeService.issueChallenge(
      'test-mission-replay',
      defaultUserId
    );

    // First proof consumes the nonce
    const { upload: upload1 } = await createBoundProof({
      sessionId: challenge.sessionId,
      sessionNonce: challenge.sessionNonce
    });
    await ProofsService.verifyWithRealVision(upload1.proofId, { minRepetitions: 0 });

    // Second proof with same nonce — should be flagged or rejected
    const { upload: upload2 } = await createBoundProof({
      sessionId: challenge.sessionId,
      sessionNonce: challenge.sessionNonce
    });

    const replayResult = await ProofsService.verifyWithRealVision(upload2.proofId, {
      minRepetitions: 0
    });

    // The consumed nonce must not pass again
    expect(replayResult.flags).toContain('INVALID_OR_REPLAYED_SESSION_NONCE');
    expect(replayResult.decision).toBe('REJECT');
  }, INFERENCE_TIMEOUT);

  it('N4: cross-session nonce mismatch — wrong nonce for a valid sessionId is REJECTED', async () => {
    const challenge = SessionChallengeService.issueChallenge(
      'test-mission-xsession',
      defaultUserId
    );

    const { upload } = await createBoundProof({
      sessionId: challenge.sessionId,
      sessionNonce: 'completely_wrong_nonce_not_issued_by_challenge_service'
    });

    const result = await ProofsService.verifyWithRealVision(upload.proofId, {
      minRepetitions: 0
    });

    expect(result.flags).toContain('INVALID_OR_REPLAYED_SESSION_NONCE');
    expect(result.decision).toBe('REJECT');
  }, INFERENCE_TIMEOUT);

  it('N5: expired challenge results in REJECT with nonce flag', async () => {
    const challenge = SessionChallengeService.issueChallenge(
      'test-mission-expired',
      defaultUserId
    );

    // Manually mark as consumed to simulate expiry scenario
    (SessionChallengeService as any).challenges?.set?.(challenge.sessionId, {
      ...challenge,
      expiresAt: new Date(Date.now() - 1000).toISOString() // expired 1s ago
    });

    const { upload } = await createBoundProof({
      sessionId: challenge.sessionId,
      sessionNonce: challenge.sessionNonce
    });

    const result = await ProofsService.verifyWithRealVision(upload.proofId, {
      minRepetitions: 0
    });

    expect(result.flags).toContain('INVALID_OR_REPLAYED_SESSION_NONCE');
    expect(result.decision).toBe('REJECT');
  }, INFERENCE_TIMEOUT);
});
