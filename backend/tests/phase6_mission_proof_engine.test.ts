// Phase 6 Mission Execution & Proof Engine Master Integration Tests
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { MissionsService } from '../src/modules/missions/missions.controller';
import { ProofsService } from '../src/modules/proofs/proofs.controller';
import { VerificationEngine } from '../src/modules/verification/verification.engine';
import { GamificationService } from '../src/modules/gamification/gamification.controller';

describe('Phase 6 Acceptance Gate: Mission Execution & Multi-Modal Proof Verification Engine', () => {
  let userId: string;
  let photoTaskId: string;
  let videoTaskId: string;
  let photoMissionId: string;
  let videoMissionId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    userId = seeded.defaultUserId;

    // 1. Photo Task: Make Bed (Requires luminance >= 30, labels: ['bed'])
    const photoTask = TasksService.createCustomTask(userId, {
      name: 'Morning Bed Alignment',
      description: 'Align sheets and pillows',
      instructions: 'Snap well-lit photo of made bed',
      category: 'MORNING',
      proofType: 'PHOTO',
      difficulty: 1,
      baseXp: 50,
      validationRules: { minLuminance: 30, requiredLabels: ['bed'] }
    });
    photoTaskId = photoTask.id;

    // 2. Video Task: Push-ups (Requires >= 10 reps, motion >= 0.5)
    const videoTask = TasksService.createCustomTask(userId, {
      name: '10 Strict Push-Ups',
      description: 'Chest-to-floor push-ups',
      instructions: 'Record 10 full reps',
      category: 'PHYSICAL',
      proofType: 'VIDEO',
      difficulty: 2,
      baseXp: 60,
      validationRules: { minRepetitions: 10, minDurationSec: 10 }
    });
    videoTaskId = videoTask.id;
  });

  it('Gate 1: Triggers photo mission and verifies presigned upload URL generation', () => {
    const mission = MissionsService.triggerMission({
      userId,
      taskId: photoTaskId,
      disciplineMode: 'DISCIPLINE'
    });
    expect(mission).toBeDefined();
    expect(mission?.status).toBe('TRIGGERED');
    photoMissionId = mission!.id;

    const presigned = ProofsService.generateUploadUrl({
      userId,
      missionId: photoMissionId,
      mediaType: 'image/jpeg'
    });

    expect(presigned.storageKey).toContain(`proofs/${userId}/${photoMissionId}/`);
    expect(presigned.uploadUrl).toBeDefined();
    expect(presigned.mediaType).toBe('image/jpeg');
  });

  it('Gate 2: Rejects photo proof when ambient illumination is below required threshold (< 30 lux)', async () => {
    const result = await ProofsService.submitAndVerify({
      missionId: photoMissionId,
      mediaType: 'image/jpeg',
      storageKey: 'dark_room_photo.jpg',
      capturedAt: new Date().toISOString(),
      deviceTelemetry: {
        ambientLux: 10, // Too dark
        detectedLabels: ['bed']
      }
    });

    expect(result.isValid).toBe(false);
    expect(result.verificationStatus).toBe('REJECTED');
    expect(result.rejectionReason).toContain('too dark');
  });

  it('Gate 3: Rejects stale photo capture older than 3 minutes', async () => {
    const staleTime = new Date(Date.now() - 4 * 60 * 1000).toISOString(); // 4 minutes ago
    const result = await ProofsService.submitAndVerify({
      missionId: photoMissionId,
      mediaType: 'image/jpeg',
      storageKey: 'old_photo.jpg',
      capturedAt: staleTime,
      deviceTelemetry: {
        ambientLux: 50,
        detectedLabels: ['bed']
      }
    });

    expect(result.isValid).toBe(false);
    expect(result.rejectionReason).toContain('stale');
  });

  it('Gate 4: Approves valid photo proof and executes atomic mission completion', async () => {
    const initialTotalXp = GamificationService.getOverview(userId).gamification.totalXp;

    const result = await ProofsService.submitAndVerify({
      missionId: photoMissionId,
      mediaType: 'image/jpeg',
      storageKey: 'valid_bed_photo.jpg',
      capturedAt: new Date().toISOString(),
      deviceTelemetry: {
        ambientLux: 65,
        detectedLabels: ['bed']
      }
    });

    expect(result.isValid).toBe(true);
    expect(result.verificationStatus).toBe('PASSED');
    expect(result.completedMission?.status).toBe('COMPLETED');

    const updatedOverview = GamificationService.getOverview(userId);
    expect(updatedOverview.gamification.totalXp).toBeGreaterThan(initialTotalXp);
  });

  it('Gate 5: Video Proof: Rejects video with insufficient repetitions (< 10 reps)', async () => {
    const mission = MissionsService.triggerMission({
      userId,
      taskId: videoTaskId,
      disciplineMode: 'DISCIPLINE'
    });
    videoMissionId = mission!.id;

    const result = await ProofsService.submitAndVerify({
      missionId: videoMissionId,
      mediaType: 'video/mp4',
      storageKey: 'partial_pushups.mp4',
      capturedAt: new Date().toISOString(),
      deviceTelemetry: {
        ambientLux: 70,
        motionCycles: 6 // Only 6 reps out of 10
      }
    });

    expect(result.isValid).toBe(false);
    expect(result.rejectionReason).toContain('Insufficient repetitions');
  });

  it('Gate 6: Video Proof: Approves full 10-rep video and awards +50% Instant Action Bonus', async () => {
    const result = await ProofsService.submitAndVerify({
      missionId: videoMissionId,
      mediaType: 'video/mp4',
      storageKey: 'complete_pushups.mp4',
      capturedAt: new Date().toISOString(),
      deviceTelemetry: {
        ambientLux: 75,
        motionCycles: 10,
        accelerometerMotion: true
      }
    });

    expect(result.isValid).toBe(true);
    expect(result.verificationStatus).toBe('PASSED');
    expect(result.completedMission?.status).toBe('COMPLETED');

    // Verify ledger received speed bonus transaction
    const ledger = GamificationService.getLedger(userId);
    const speedBonusTx = ledger.transactions.find((t) => t.reason === 'FIRST_ATTEMPT_SPEED_BONUS');
    expect(speedBonusTx).toBeDefined();
  });

  it('Gate 7: Idempotency Protection: Re-submitting proof on completed mission does not duplicate XP', async () => {
    const initialTotalXp = GamificationService.getOverview(userId).gamification.totalXp;

    const duplicateResult = await ProofsService.submitAndVerify({
      missionId: videoMissionId,
      mediaType: 'video/mp4',
      storageKey: 'complete_pushups.mp4',
      capturedAt: new Date().toISOString(),
      deviceTelemetry: { ambientLux: 75, motionCycles: 10 }
    });

    expect(duplicateResult.isValid).toBe(true);

    const postDuplicateXp = GamificationService.getOverview(userId).gamification.totalXp;
    expect(postDuplicateXp).toBe(initialTotalXp); // No extra XP added
  });

  it('Gate 8: Audits proof record persistence and telemetry metadata', () => {
    const db = DatabaseService.getDb();
    const row = db.prepare("SELECT id FROM proofs WHERE mission_id = ? AND verification_status = 'PASSED' LIMIT 1").get(videoMissionId) as any;
    expect(row).toBeDefined();

    const fetched = ProofsService.getById(row.id);
    expect(fetched).toBeDefined();
    expect(fetched?.mediaType).toBe('video/mp4');
    expect(fetched?.verificationStatus).toBe('PASSED');
    expect(fetched?.publicUrl).toContain('habitat-proofs');
  });
});
