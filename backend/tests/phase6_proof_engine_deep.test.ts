// Phase 6 Proof Engine Deep Integration Tests
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { MissionsService } from '../src/modules/missions/missions.controller';
import { ProofsService } from '../src/modules/proofs/proofs.controller';
import { ProofStateMachine } from '../src/modules/proofs/domain/proof-state-machine';
import { BasicVerificationProvider } from '../src/modules/proofs/verification/basic-verification.provider';

describe('Phase 6 Acceptance Gate: Proof Capture, State Machine & Basic Verification Engine', () => {
  let userId: string;
  let taskId: string;
  let missionId: string;
  let proofId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    userId = seeded.defaultUserId;

    const task = TasksService.createCustomTask(userId, {
      name: 'Sunlight Exposure & Hydration',
      description: 'Drink 500ml water outside',
      instructions: 'Snap well-lit photo of water bottle in morning light',
      category: 'HEALTH',
      proofType: 'PHOTO',
      difficulty: 1,
      baseXp: 40
    });
    taskId = task.id;
  });

  it('Gate 1: Proof State Machine enforces legal transition sequence', () => {
    expect(ProofStateMachine.canTransition('CAPTURING', 'CAPTURED')).toBe(true);
    expect(ProofStateMachine.canTransition('CAPTURED', 'UPLOAD_PENDING')).toBe(true);
    expect(ProofStateMachine.canTransition('UPLOAD_PENDING', 'UPLOADING')).toBe(true);
    expect(ProofStateMachine.canTransition('UPLOADING', 'UPLOADED')).toBe(true);
    expect(ProofStateMachine.canTransition('UPLOADED', 'VALIDATING')).toBe(true);
    expect(ProofStateMachine.canTransition('VALIDATING', 'ACCEPTED')).toBe(true);

    // Illegal Transitions
    expect(ProofStateMachine.canTransition('DELETED', 'UPLOADING')).toBe(false);
    expect(ProofStateMachine.canTransition('ACCEPTED', 'CAPTURING')).toBe(false);

    expect(() => ProofStateMachine.assertTransition('DELETED', 'UPLOADING')).toThrow(
      'Illegal Proof State Transition'
    );
  });

  it('Gate 2: Basic Verification Provider rejects empty file or invalid format', () => {
    // 1. Empty file
    const emptyCheck = BasicVerificationProvider.verify({
      proofType: 'PHOTO',
      mimeType: 'image/jpeg',
      fileSizeBytes: 0,
      capturedAt: new Date().toISOString(),
      rules: {}
    });
    expect(emptyCheck.status).toBe('REJECTED');
    expect(emptyCheck.reasonCode).toBe('INVALID_FILE');

    // 2. Unsupported format
    const formatCheck = BasicVerificationProvider.verify({
      proofType: 'PHOTO',
      mimeType: 'application/pdf',
      fileSizeBytes: 1024,
      capturedAt: new Date().toISOString(),
      rules: {}
    });
    expect(formatCheck.status).toBe('REJECTED');
    expect(formatCheck.reasonCode).toBe('INVALID_FORMAT');
  });

  it('Gate 3: Basic Verification Provider validates video duration constraints', () => {
    // Too short (< 10s)
    const shortCheck = BasicVerificationProvider.verify({
      proofType: 'VIDEO',
      mimeType: 'video/mp4',
      fileSizeBytes: 2048,
      durationSeconds: 4,
      capturedAt: new Date().toISOString(),
      rules: { minDurationSeconds: 10, maxDurationSeconds: 60 }
    });
    expect(shortCheck.status).toBe('REJECTED');
    expect(shortCheck.reasonCode).toBe('VIDEO_TOO_SHORT');

    // Too long (> 60s)
    const longCheck = BasicVerificationProvider.verify({
      proofType: 'VIDEO',
      mimeType: 'video/mp4',
      fileSizeBytes: 2048,
      durationSeconds: 75,
      capturedAt: new Date().toISOString(),
      rules: { minDurationSeconds: 10, maxDurationSeconds: 60 }
    });
    expect(longCheck.status).toBe('REJECTED');
    expect(longCheck.reasonCode).toBe('VIDEO_TOO_LONG');

    // Valid (15s)
    const validCheck = BasicVerificationProvider.verify({
      proofType: 'VIDEO',
      mimeType: 'video/mp4',
      fileSizeBytes: 2048,
      durationSeconds: 15,
      capturedAt: new Date().toISOString(),
      rules: { minDurationSeconds: 10, maxDurationSeconds: 60 }
    });
    expect(validCheck.status).toBe('ACCEPTED');
    expect(validCheck.reasonCode).toBeNull();
  });

  it('Gate 4: Mission lifecycle: startMission transitions status to ACTIVE', () => {
    const mission = MissionsService.triggerMission({
      userId,
      taskId,
      disciplineMode: 'DISCIPLINE'
    });
    missionId = mission!.id;

    const started = MissionsService.startMission(missionId);
    expect(started?.status).toBe('ACTIVE');
  });

  it('Gate 5: Creates proof entry and transitions mission to AWAITING_PROOF', () => {
    const proof = ProofsService.createProof(missionId, userId, 'PHOTO');
    expect(proof).toBeDefined();
    expect(proof?.verificationStatus).toBe('CAPTURED');
    proofId = proof!.id;

    const mission = MissionsService.getById(missionId);
    expect(mission?.status).toBe('AWAITING_PROOF');
  });

  it('Gate 6: Attaches proof asset and generates signed upload session', () => {
    const assetSession = ProofsService.addProofAsset(proofId, {
      mimeType: 'image/jpeg',
      fileSizeBytes: 500 * 1024,
      width: 1920,
      height: 1080
    });

    expect(assetSession).toBeDefined();
    expect(assetSession.uploadUrl).toContain('habitat-proofs');
    expect(assetSession.storageKey).toContain(`proofs/assets/${proofId}/`);
  });

  it('Gate 7: Submitting valid proof completes mission atomically', async () => {
    const result = await ProofsService.submitAndVerify({
      missionId,
      mediaType: 'image/jpeg',
      storageKey: 'valid_sunlight_proof.jpg',
      capturedAt: new Date().toISOString(),
      deviceTelemetry: {
        ambientLux: 60,
        fileSizeBytes: 500 * 1024
      }
    });

    expect(result.isValid).toBe(true);
    expect(result.verificationStatus).toBe('PASSED');
    expect(result.completedMission?.status).toBe('COMPLETED');
  });

  it('Gate 8: Soft-deleting proof preserves historical mission completion', () => {
    const deleted = ProofsService.deleteProof(proofId);
    expect(deleted).toBe(true);

    const proof = ProofsService.getById(proofId);
    expect(proof?.verificationStatus).toBe('DELETED');

    const mission = MissionsService.getById(missionId);
    expect(mission?.status).toBe('COMPLETED'); // Mission remains completed!
  });
});
