// Phase 9 Verification & Truth Engine Master Acceptance Tests
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { MissionsService } from '../src/modules/missions/missions.controller';
import { ProofsService } from '../src/modules/proofs/proofs.controller';
import { VerificationTruthService } from '../src/modules/verification/verification.service';
import { GamificationService } from '../src/modules/gamification/gamification.controller';

describe('Phase 9 Acceptance Gate: Verification & Truth Engine (Anti-Cheat, CV Object Detection & Pose Rep Counter)', () => {
  let userId: string;
  let bedTaskId: string;
  let waterTaskId: string;
  let pushupTaskId: string;
  let bedMissionId: string;
  let waterMissionId: string;
  let pushupMissionId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    userId = seeded.defaultUserId;

    // 1. Task: Make Bed (CV Objects: bed, pillow, blanket)
    const bedTask = TasksService.createCustomTask(userId, {
      name: 'Make Your Bed',
      description: 'Tight corners, aligned pillows',
      category: 'MORNING',
      proofType: 'PHOTO',
      difficulty: 1,
      baseXp: 30,
      validationRules: {
        minLuminance: 25,
        requiredLabels: ['bed', 'pillow', 'blanket']
      }
    });
    bedTaskId = bedTask.id;

    // 2. Task: Morning Hydration (CV Objects: glass, bottle, water)
    const waterTask = TasksService.createCustomTask(userId, {
      name: 'Drink 500ml Water',
      description: 'Full glass of water',
      category: 'HEALTH',
      proofType: 'PHOTO',
      difficulty: 1,
      baseXp: 25,
      validationRules: {
        minLuminance: 25,
        requiredLabels: ['glass', 'bottle', 'water']
      }
    });
    waterTaskId = waterTask.id;

    // 3. Task: 10 Pushups (Pose Estimation: 10 reps)
    const pushupTask = TasksService.createCustomTask(userId, {
      name: '10 Strict Push-Ups',
      description: 'Chest to deck, full lockout',
      category: 'PHYSICAL',
      proofType: 'VIDEO',
      difficulty: 2,
      baseXp: 50,
      validationRules: {
        minDurationSec: 5,
        minRepetitions: 10
      }
    });
    pushupTaskId = pushupTask.id;

    // Trigger Missions
    const mBed = MissionsService.triggerMission({
      userId,
      taskId: bedTaskId,
      disciplineMode: 'DISCIPLINE'
    });
    bedMissionId = mBed!.id;

    const mWater = MissionsService.triggerMission({
      userId,
      taskId: waterTaskId,
      disciplineMode: 'DISCIPLINE'
    });
    waterMissionId = mWater!.id;

    const mPushup = MissionsService.triggerMission({
      userId,
      taskId: pushupTaskId,
      disciplineMode: 'DISCIPLINE'
    });
    pushupMissionId = mPushup!.id;
  });

  it('Gate 1: Anti-Cheat: Rejects stale captures older than 3 minutes (> 180s)', () => {
    const staleTime = new Date(Date.now() - 250 * 1000).toISOString();

    const result = VerificationTruthService.evaluateProof({
      missionId: bedMissionId,
      telemetry: {
        capturedAt: staleTime,
        ambientLux: 45,
        entropyScore: 0.88,
        detectedLabels: ['bed', 'pillow']
      }
    });

    expect(result.isValid).toBe(false);
    expect(result.missionStatus).toBe('ACTIVE');
    expect(result.rejectionReason).toContain('stale');
    expect(result.actionableAdvice).toBeDefined();
  });

  it('Gate 2: Anti-Cheat: Rejects low-illumination pitch-black scenes (< 25 lux)', () => {
    const result = VerificationTruthService.evaluateProof({
      missionId: bedMissionId,
      telemetry: {
        capturedAt: new Date().toISOString(),
        ambientLux: 10, // pitch-black under blanket
        entropyScore: 0.85,
        detectedLabels: ['bed']
      }
    });

    expect(result.isValid).toBe(false);
    expect(result.missionStatus).toBe('ACTIVE');
    expect(result.rejectionReason).toContain('too dark');
  });

  it('Gate 3: Anti-Cheat: Rejects optical lens covering (low optical entropy score < 0.15)', () => {
    const result = VerificationTruthService.evaluateProof({
      missionId: bedMissionId,
      telemetry: {
        capturedAt: new Date().toISOString(),
        ambientLux: 60,
        entropyScore: 0.05, // solid black finger over lens
        detectedLabels: []
      }
    });

    expect(result.isValid).toBe(false);
    expect(result.missionStatus).toBe('ACTIVE');
    expect(result.rejectionReason).toContain('covered or obscured');
  });

  it('Gate 4: Smart CV: Validates object labels for "Make Bed" and "Morning Hydration" tasks', () => {
    // 1. Evaluate Make Bed with detected objects: 'bed', 'pillow'
    const bedResult = VerificationTruthService.evaluateProof({
      missionId: bedMissionId,
      telemetry: {
        capturedAt: new Date().toISOString(),
        ambientLux: 55,
        entropyScore: 0.90,
        detectedLabels: ['bed', 'pillow', 'bedroom_furniture']
      }
    });

    expect(bedResult.isValid).toBe(true);
    expect(bedResult.strategyUsed).toBe('OBJECT_DETECTION_CV');
    expect(bedResult.confidenceScore).toBeGreaterThanOrEqual(0.75);
    expect(bedResult.missionStatus).toBe('COMPLETED');
    expect(bedResult.xpAwarded).toBe(30);

    // 2. Evaluate Morning Hydration with detected objects: 'glass', 'water'
    const waterResult = VerificationTruthService.evaluateProof({
      missionId: waterMissionId,
      telemetry: {
        capturedAt: new Date().toISOString(),
        ambientLux: 50,
        entropyScore: 0.85,
        detectedLabels: ['glass', 'water_bottle']
      }
    });

    expect(waterResult.isValid).toBe(true);
    expect(waterResult.strategyUsed).toBe('OBJECT_DETECTION_CV');
    expect(waterResult.confidenceScore).toBeGreaterThanOrEqual(0.75);
    expect(waterResult.missionStatus).toBe('COMPLETED');
  });

  it('Gate 5: Smart CV: Rejects photo when required target object is missing from frame', () => {
    // Trigger fresh bed mission
    const freshBedMission = MissionsService.triggerMission({
      userId,
      taskId: bedTaskId,
      disciplineMode: 'DISCIPLINE'
    });

    const result = VerificationTruthService.evaluateProof({
      missionId: freshBedMission!.id,
      telemetry: {
        capturedAt: new Date().toISOString(),
        ambientLux: 50,
        entropyScore: 0.85,
        detectedLabels: ['television', 'laptop', 'sofa'] // no bed/pillow
      }
    });

    expect(result.isValid).toBe(false);
    expect(result.strategyUsed).toBe('OBJECT_DETECTION_CV');
    expect(result.rejectionReason).toContain('Required target object not detected');
  });

  it('Gate 6: Pose Rep Counter: Approves full 10-rep video with high confidence score', () => {
    const result = VerificationTruthService.evaluateProof({
      missionId: pushupMissionId,
      telemetry: {
        capturedAt: new Date().toISOString(),
        ambientLux: 60,
        entropyScore: 0.92,
        motionCycles: 10,
        poseConfidence: 0.95
      }
    });

    expect(result.isValid).toBe(true);
    expect(result.strategyUsed).toBe('POSE_ESTIMATION_REPS');
    expect(result.confidenceScore).toBeGreaterThanOrEqual(0.90);
    expect(result.missionStatus).toBe('COMPLETED');
    expect(result.extractedMetrics.repsCounted).toBe(10);
  });

  it('Gate 7: Pose Rep Counter: Rejects video with insufficient repetitions (< 10 reps)', () => {
    // Trigger fresh push-up mission
    const freshPushupMission = MissionsService.triggerMission({
      userId,
      taskId: pushupTaskId,
      disciplineMode: 'DISCIPLINE'
    });

    const result = VerificationTruthService.evaluateProof({
      missionId: freshPushupMission!.id,
      telemetry: {
        capturedAt: new Date().toISOString(),
        ambientLux: 60,
        entropyScore: 0.92,
        motionCycles: 4, // only 4 reps
        poseConfidence: 0.90
      }
    });

    expect(result.isValid).toBe(false);
    expect(result.strategyUsed).toBe('POSE_ESTIMATION_REPS');
    expect(result.rejectionReason).toContain('Insufficient repetitions detected');
    expect(result.actionableAdvice).toContain('10 complete repetitions');
  });

  it('Gate 8: Audits Verification Report and validates XP transaction ledger entries', () => {
    const report = VerificationTruthService.getReport(pushupMissionId);
    expect(report).toBeDefined();
    expect(report?.strategyUsed).toBe('POSE_ESTIMATION_REPS');
    expect(report?.isValid).toBe(true);
    expect(report?.extractedMetrics.repsCounted).toBe(10);

    // Verify gamification XP overview updated
    const overview = GamificationService.getOverview(userId);
    expect(overview.gamification.totalXp).toBeGreaterThan(0);
  });
});
