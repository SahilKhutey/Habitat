// Phase 8 Camera & Proof Capture System Master Integration Tests
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { MissionsService } from '../src/modules/missions/missions.controller';
import { ProofsService } from '../src/modules/proofs/proofs.controller';
import { proofLimits } from '../src/modules/proofs/domain/proof.rules';

describe('Phase 8 Acceptance Gate: Camera & Proof Capture Pipeline & Direct S3 Upload Sessions', () => {
  let userAId: string;
  let userBId: string;
  let photoTaskId: string;
  let videoTaskId: string;
  let photoMissionId: string;
  let videoMissionId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    userAId = seeded.defaultUserId;

    // Create User B for security tests
    const db = DatabaseService.getDb();
    userBId = 'user-b-security-test';
    db.prepare(`
      INSERT OR IGNORE INTO users (id, email, password_hash, display_name, timezone, created_at, updated_at)
      VALUES (?, 'userb@habitat.app', 'hash123', 'User B', 'UTC', datetime('now'), datetime('now'))
    `).run(userBId);

    // 1. Photo Task
    const photoTask = TasksService.createCustomTask(userAId, {
      name: 'Take Photo Outside',
      description: 'Morning light exposure',
      category: 'MORNING',
      proofType: 'PHOTO',
      difficulty: 1,
      baseXp: 35
    });
    photoTaskId = photoTask.id;

    // 2. Video Task
    const videoTask = TasksService.createCustomTask(userAId, {
      name: '10 Morning Push-Ups',
      description: 'Record 10 clean pushups',
      category: 'PHYSICAL',
      proofType: 'VIDEO',
      difficulty: 2,
      baseXp: 50
    });
    videoTaskId = videoTask.id;

    // Trigger Missions
    const mPhoto = MissionsService.triggerMission({
      userId: userAId,
      taskId: photoTaskId,
      disciplineMode: 'DISCIPLINE'
    });
    photoMissionId = mPhoto!.id;

    const mVideo = MissionsService.triggerMission({
      userId: userAId,
      taskId: videoTaskId,
      disciplineMode: 'DISCIPLINE'
    });
    videoMissionId = mVideo!.id;
  });

  it('Gate 1: Creates Direct S3 / MinIO Upload Session with Signed URL and 15-min expiry', () => {
    const session = ProofsService.createUploadSession({
      userId: userAId,
      missionId: photoMissionId,
      type: 'PHOTO',
      mimeType: 'image/jpeg',
      sizeBytes: 850000,
      width: 1920,
      height: 1080
    });

    expect(session).toBeDefined();
    expect(session.proofId).toBeDefined();
    expect(session.uploadUrl).toContain('http');
    expect(session.uploadUrl).toContain('proofs/');
    expect(session.objectKey).toContain(photoMissionId);
    expect(session.expiresAt).toBeDefined();

    // Verify DB record initialized in UPLOADING state
    const db = DatabaseService.getDb();
    const proof = db.prepare('SELECT * FROM proofs WHERE id = ?').get(session.proofId) as any;
    expect(proof).toBeDefined();
    expect(proof.verification_status).toBe('UPLOADING');
    expect(proof.mime_type).toBe('image/jpeg');
    expect(proof.size_bytes).toBe(850000);
  });

  it('Gate 2: File Limits Enforcement: Rejects invalid MIME format, zero-byte file, and oversized payloads', () => {
    // 1. Invalid MIME (executable disguised as photo)
    expect(() =>
      ProofsService.createUploadSession({
        userId: userAId,
        missionId: photoMissionId,
        type: 'PHOTO',
        mimeType: 'application/x-msdownload',
        sizeBytes: 500000
      })
    ).toThrow('INVALID_FORMAT');

    // 2. Empty file
    expect(() =>
      ProofsService.createUploadSession({
        userId: userAId,
        missionId: photoMissionId,
        type: 'PHOTO',
        mimeType: 'image/jpeg',
        sizeBytes: 0
      })
    ).toThrow('INVALID_FILE');

    // 3. Oversized Photo (> 15 MB)
    expect(() =>
      ProofsService.createUploadSession({
        userId: userAId,
        missionId: photoMissionId,
        type: 'PHOTO',
        mimeType: 'image/jpeg',
        sizeBytes: proofLimits.photoMaxBytes + 1024
      })
    ).toThrow('FILE_TOO_LARGE');

    // 4. Video exceeding max duration (> 60s)
    expect(() =>
      ProofsService.createUploadSession({
        userId: userAId,
        missionId: videoMissionId,
        type: 'VIDEO',
        mimeType: 'video/mp4',
        sizeBytes: 5000000,
        durationSeconds: 75
      })
    ).toThrow('VIDEO_TOO_LONG');
  });

  it('Gate 3: Confirms direct upload completion and transitions proof to REGISTERED', () => {
    const session = ProofsService.createUploadSession({
      userId: userAId,
      missionId: photoMissionId,
      type: 'PHOTO',
      mimeType: 'image/png',
      sizeBytes: 1200000
    });

    // Client uploads directly to S3 and calls complete-upload
    const registered = ProofsService.completeUpload(session.proofId, userAId);

    expect(registered).toBeDefined();
    expect(registered.verificationStatus).toBe('REGISTERED');
    expect(registered.objectKey).toBe(session.objectKey);
  });

  it('Gate 4: Submits registered proof to mission and transitions mission IN_PROGRESS -> VERIFYING', () => {
    // Start mission
    MissionsService.startMission(photoMissionId, userAId);

    // Create and register proof
    const session = ProofsService.createUploadSession({
      userId: userAId,
      missionId: photoMissionId,
      type: 'PHOTO',
      mimeType: 'image/jpeg',
      sizeBytes: 950000
    });
    ProofsService.completeUpload(session.proofId, userAId);

    // Submit to mission
    const result = ProofsService.submitProofToMission({
      missionId: photoMissionId,
      proofId: session.proofId,
      userId: userAId
    });

    expect(result.success).toBe(true);
    expect(result.status).toBe('VERIFYING');

    const mission = MissionsService.getById(photoMissionId);
    expect(mission?.status).toBe('VERIFYING');

    const proof = ProofsService.getById(session.proofId);
    expect(proof?.verificationStatus).toBe('SUBMITTED');
  });

  it('Gate 5: Retake Flow: Discards unsubmitted draft proof while preserving attempt', () => {
    const draftSession = ProofsService.createUploadSession({
      userId: userAId,
      missionId: photoMissionId,
      type: 'PHOTO',
      mimeType: 'image/jpeg',
      sizeBytes: 400000
    });

    // User chooses Retake
    const deleted = ProofsService.deleteProof(draftSession.proofId, userAId);
    expect(deleted).toBe(true);

    const proof = ProofsService.getById(draftSession.proofId);
    expect(proof?.verificationStatus).toBe('DELETED');
  });

  it('Gate 6: Security & Ownership: Prevents User B from completing or submitting User A proof', () => {
    const userASession = ProofsService.createUploadSession({
      userId: userAId,
      missionId: videoMissionId,
      type: 'VIDEO',
      mimeType: 'video/mp4',
      sizeBytes: 8500000,
      durationSeconds: 15
    });

    // User B attempts to complete User A upload -> Unauthorized
    expect(() => ProofsService.completeUpload(userASession.proofId, userBId)).toThrow('UNAUTHORIZED');

    // User B attempts to submit proof to mission -> Unauthorized
    expect(() =>
      ProofsService.submitProofToMission({
        missionId: videoMissionId,
        proofId: userASession.proofId,
        userId: userBId
      })
    ).toThrow('UNAUTHORIZED');
  });

  it('Gate 7: Video Proof Metadata: Stores duration, video MIME container, and thumbnail key', () => {
    const videoSession = ProofsService.createUploadSession({
      userId: userAId,
      missionId: videoMissionId,
      type: 'VIDEO',
      mimeType: 'video/mp4',
      sizeBytes: 12500000,
      durationSeconds: 22
    });

    expect(videoSession.thumbnailKey).toBeDefined();
    expect(videoSession.thumbnailKey).toContain('_thumb.jpg');

    const proof = ProofsService.getById(videoSession.proofId);
    expect(proof?.durationMs).toBe(22000);
    expect(proof?.mimeType).toBe('video/mp4');
    expect(proof?.thumbnailKey).toContain('_thumb.jpg');
  });
});
