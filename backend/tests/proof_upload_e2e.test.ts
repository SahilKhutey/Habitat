// End-to-End Tests: Complete Proof Upload, Storage Validation & Verification Pipeline
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'fs';
import path from 'path';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { ProofsService } from '../src/modules/proofs/proofs.controller';
import { proofRepository } from '../src/repositories/proof.repository';
import { MissionRepository } from '../src/repositories/mission.repository';
import { StorageFactory } from '../src/modules/storage/storage.factory';
import { LocalStorageProvider } from '../src/modules/storage/infrastructure/local-storage.provider';
import { VerificationEngine } from '../src/modules/verification/verification.engine';
import { SessionChallengeService } from '../src/modules/proofs/services/session-challenge.service';
import { VerificationEvidence } from '../src/modules/verification/domain/evidence.types';

describe('Proof Upload, Storage & Verification End-to-End Lifecycle', () => {
  const testUploadsDir = path.resolve(__dirname, 'temp_e2e_uploads');
  let defaultUserId: string;
  let missionId: string;

  beforeEach(() => {
    DatabaseService.resetDbForTesting();
    SessionChallengeService.resetForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;

    if (!fs.existsSync(testUploadsDir)) {
      fs.mkdirSync(testUploadsDir, { recursive: true });
    }

    const localProvider = new LocalStorageProvider(testUploadsDir);
    StorageFactory.setProvider(localProvider);

    const db = DatabaseService.getDb();
    const task = db.prepare('SELECT id FROM tasks LIMIT 1').get() as { id: string };

    // Create active push-up mission
    const mission = MissionRepository.create({
      userId: defaultUserId,
      taskId: task.id,
      disciplineMode: 'DISCIPLINE'
    });
    missionId = mission.id;
  });

  afterEach(() => {
    StorageFactory.resetForTesting();
    if (fs.existsSync(testUploadsDir)) {
      fs.rmSync(testUploadsDir, { recursive: true, force: true });
    }
  });

  it('executes full upload session, binary storage validation, SHA-256 hashing and download URL generation', async () => {
    // 1. Client requests upload session
    const session = await ProofsService.createUploadSession({
      userId: defaultUserId,
      missionId,
      type: 'VIDEO',
      mimeType: 'video/mp4',
      sizeBytes: 1048576,
      durationSeconds: 15
    });

    expect(session.uploadId).toBeDefined();
    expect(session.proofId).toBeDefined();
    expect(session.objectKey).toContain(`proofs/${defaultUserId}/${missionId}/${session.proofId}/original.mp4`);

    // Verify pending proof record created in DB
    const pendingProof = proofRepository.findById(session.proofId);
    expect(pendingProof).toBeDefined();
    expect(pendingProof?.verificationStatus).toBe('UPLOADING');

    // 2. Client directly uploads media binary to storage
    const provider = StorageFactory.getProvider() as LocalStorageProvider;
    const testVideoBuffer = Buffer.from('RAW_SIMULATED_PUSHUP_VIDEO_STREAM_BYTES_CONTENT_123456789');
    await provider.saveBuffer(session.objectKey, testVideoBuffer, 'video/mp4');

    // 3. Client calls completeUpload handshake
    const completedProof = await ProofsService.completeUpload(session.proofId, defaultUserId);
    expect(completedProof).toBeDefined();
    expect(completedProof?.verification_status || completedProof?.verificationStatus).toBe('REGISTERED');
    expect(completedProof?.size_bytes || completedProof?.sizeBytes).toBeGreaterThan(0);
    expect(completedProof?.sha256).toBeDefined();
    expect(completedProof?.uploadedAt).toBeDefined();

    // 4. Request signed download URL
    const downloadUrl = await ProofsService.getDownloadUrl(session.proofId);
    expect(downloadUrl).toContain('/api/v1/storage/file');
    expect(downloadUrl).toContain(encodeURIComponent(session.objectKey));

    // 5. Verification evaluation takes place
    const challenge = SessionChallengeService.issueChallenge(missionId, defaultUserId);

    const mockEvidence: VerificationEvidence = {
      sessionId: challenge.sessionId,
      sessionNonce: challenge.sessionNonce,
      missionId,
      taskSlug: 'tpl-pushups-10',
      startedAt: new Date(Date.now() - 10000).toISOString(),
      completedAt: new Date().toISOString(),
      durationMs: 10000,
      pose: {
        model: 'MoveNet-Lightning',
        modelVersion: '1.0.0',
        totalFramesSampled: 300,
        meanPoseConfidence: 0.96,
        frameTrajectory: Array.from({ length: 300 }, (_, i) => ({
          timestampMs: i * 33,
          frameIndex: i,
          frameHash: `hash_${i}_${(i % 30)}`,
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
        livenessScore: 0.95,
        temporalContinuityScore: 1.0,
        frameUniquenessScore: 1.0,
        trajectoryConsistencyScore: 0.95,
        motionContinuityScore: 1.0,
        replayRiskScore: 0.0,
        challengePassed: true
      },
      integrity: {
        clientAppVersion: '1.0.0',
        evidencePayloadHash: completedProof?.sha256 || 'hash'
      }
    };

    const verificationResult = VerificationEngine.verifyEvidence(mockEvidence, { minRepetitions: 10 });
    expect(verificationResult.decision).toBe('ACCEPT');
    expect(verificationResult.repsVerified).toBe(10);

    // 6. Record final verification decision on proof record
    proofRepository.updateVerification(session.proofId, 'ACCEPTED', null);
    const finalProof = proofRepository.findById(session.proofId);
    expect(finalProof?.verificationStatus).toBe('ACCEPTED');
    expect(finalProof?.verifiedAt).toBeDefined();
  });
});
