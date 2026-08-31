// Integration Test: Storage to Real MoveNet Extraction to Proof Decision Pipeline
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { StorageFactory } from '../src/modules/storage/storage.factory';
import { PoseExtractionService } from '../src/modules/verification/services/pose-extraction.service';
import { ProofsService } from '../src/modules/proofs/proofs.controller';
import { MissionsService } from '../src/modules/missions/missions.controller';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { MoveNetLightningEngine } from '../src/modules/verification/engine/movenet-lightning.engine';
import { PoseGeometryCalculator } from '../src/modules/verification/engine/pose-geometry.calculator';
import { Keypoint } from '../src/modules/verification/domain/evidence.types';

describe('Storage to Pose Extraction & Real Vision Decision Pipeline', () => {
  let defaultUserId: string;

  beforeAll(async () => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;
    process.env.VISION_PROVIDER = 'movenet';
    await MoveNetLightningEngine.initialize();
  });

  it('1. Calculates precise geometric angles from keypoint coordinates', () => {
    // Top position: straight arm 180 degrees
    const topKeypoints: Keypoint[] = [
      { name: 'left_shoulder', x: 0.3, y: 0.2, score: 0.95 },
      { name: 'left_elbow', x: 0.3, y: 0.5, score: 0.95 },
      { name: 'left_wrist', x: 0.3, y: 0.8, score: 0.95 },
      { name: 'right_shoulder', x: 0.4, y: 0.2, score: 0.95 },
      { name: 'right_elbow', x: 0.4, y: 0.5, score: 0.95 },
      { name: 'right_wrist', x: 0.4, y: 0.8, score: 0.95 },
      { name: 'left_hip', x: 0.6, y: 0.4, score: 0.95 },
      { name: 'left_ankle', x: 0.9, y: 0.6, score: 0.95 }
    ];

    const topMetrics = PoseGeometryCalculator.calculateMetrics(topKeypoints);
    expect(topMetrics.leftElbowAngleDeg).toBeCloseTo(180, 0);
    expect(topMetrics.isLockout).toBe(true);

    // Bottom position: bent 90 degrees
    const bottomKeypoints: Keypoint[] = [
      { name: 'left_shoulder', x: 0.2, y: 0.5, score: 0.95 },
      { name: 'left_elbow', x: 0.5, y: 0.5, score: 0.95 },
      { name: 'left_wrist', x: 0.5, y: 0.8, score: 0.95 }
    ];

    const bottomMetrics = PoseGeometryCalculator.calculateMetrics(bottomKeypoints);
    expect(bottomMetrics.leftElbowAngleDeg).toBeCloseTo(90, 0);
    expect(bottomMetrics.isDeepBottom).toBe(true);
  });

  it('2. Extracts real media bytes from storage and derives trajectory via PoseExtractionService', async () => {
    const storage = StorageFactory.getProvider();
    const objectKey = 'proofs/test_user/test_mission/proof_1/original.jpg';

    // Synthesize an RGB frame buffer
    const frameBuffer = Buffer.alloc(192 * 192 * 3, 50);
    await storage.saveBuffer!(objectKey, frameBuffer, 'image/jpeg');

    const bufferReadBack = await storage.getObjectBuffer(objectKey);
    expect(bufferReadBack.length).toBe(192 * 192 * 3);

    const service = new PoseExtractionService({ storageProvider: storage });
    const result = await service.extractPoseFromStorage(objectKey, {
      taskSlug: 'tpl-pushups-10'
    });

    expect(result).toBeDefined();
    expect(result.evidence).toBeDefined();
    expect(result.evidence.pose.model).toBe('MoveNet-Lightning');
    expect(result.frames.length).toBeGreaterThan(0);
  }, 30000);

  it('3. Runs complete ProofsService.verifyWithRealVision through storage, model, and decision engine', async () => {
    const db = DatabaseService.getDb();
    const tasks = TasksService.getAll();
    const pushupTask = tasks.find((t) => t.slug === 'pushups') || tasks[0];

    const mission = MissionsService.triggerMission({
      userId: defaultUserId,
      taskId: pushupTask.id,
      disciplineMode: 'DISCIPLINE'
    });

    expect(mission).toBeDefined();

    // Create proof session and save dummy file
    const uploadSession = ProofsService.createUploadSession({
      userId: defaultUserId,
      missionId: mission!.id,
      type: 'PHOTO',
      mimeType: 'image/jpeg',
      sizeBytes: 192 * 192 * 3
    });

    const storage = StorageFactory.getProvider();
    const testData = Buffer.alloc(192 * 192 * 3, 50);
    await storage.saveBuffer!(uploadSession.objectKey, testData, 'image/jpeg');

    // Execute real vision verification from storage
    const verification = await ProofsService.verifyWithRealVision(uploadSession.proofId, {
      minRepetitions: 0,
      skipNonceValidation: true
    });

    expect(verification).toBeDefined();
    expect(verification.proofId).toBe(uploadSession.proofId);
    expect(verification.evidence).toBeDefined();
    expect(['ACCEPT', 'REVIEW', 'REJECT']).toContain(verification.decision);

    // Check DB status was updated
    const updatedProof = db.prepare('SELECT * FROM proofs WHERE id = ?').get(uploadSession.proofId) as any;
    expect(['ACCEPTED', 'REJECTED']).toContain(updatedProof.verification_status);
  }, 30000);
});
