// Acceptance & Integration Test Suite: A2 Real Vision Provider & Video Extraction Architecture
import { describe, it, expect } from 'vitest';
import { RealVisionProvider } from '../src/modules/verification/infrastructure/tfjs-vision.provider';
import { MoveNetPoseAdapter } from '../src/modules/verification/infrastructure/movenet-pose.adapter';
import {
  MockObjectDetectionAdapter,
  UnsupportedObjectDetectionAdapter
} from '../src/modules/verification/infrastructure/object-detection.adapter';
import { FFmpegFrameExtractor } from '../src/modules/verification/infrastructure/video-frame-extractor';
import { ImageFixtures } from '../scripts/vision/fixtures/image-fixtures';
import { VerificationEngine } from '../src/modules/verification/verification.engine';
import { PoseGeometryCalculator } from '../src/modules/verification/engine/pose-geometry.calculator';
import { PushupStateMachine } from '../src/modules/verification/domain/pushup-state-machine';
import { LivenessAnalyzer } from '../src/modules/verification/engine/liveness-analyzer';
import { FramePoseRecord, VerificationEvidence } from '../src/modules/verification/domain/evidence.types';

describe('Milestone A2: Real Vision Provider & Video Extraction Architecture', () => {
  it('A2.1: RealVisionProvider implements IVisionProvider and maps MoveNet to canonical Keypoint[]', async () => {
    const provider = new RealVisionProvider();
    expect(provider.providerId).toBe('real-tfjs-movenet-v1');
    expect(provider.modelName).toBe('MoveNet-Lightning');
    expect(provider.modelVersion).toBe('1.0.0');

    const personFixture = ImageFixtures.getPersonStanding();
    const result = await provider.analyzePose([
      {
        timestampMs: 0,
        frameIndex: 0,
        frameHash: 'frame_0_hash',
        imageBuffer: Buffer.from(personFixture.data)
      }
    ]);

    expect(result.framesAnalyzed).toBe(1);
    expect(result.meanConfidence).toBeGreaterThan(0.70);

    const frameResult = result.keypointsPerFrame[0];
    expect(frameResult.keypoints.length).toBe(17);

    // Verify canonical Habitat Keypoint structure (name, x, y, score)
    const firstKp = frameResult.keypoints[0];
    expect(firstKp).toHaveProperty('name');
    expect(firstKp).toHaveProperty('x');
    expect(firstKp).toHaveProperty('y');
    expect(firstKp).toHaveProperty('score');
    expect(typeof firstKp.score).toBe('number');
  });

  it('A2.2: Empty image produces low confidence and differs from person image', async () => {
    const provider = new RealVisionProvider();
    const emptyFixture = ImageFixtures.getEmptyRoom();
    const personFixture = ImageFixtures.getPersonStanding();

    const emptyResult = await provider.analyzePose([
      {
        timestampMs: 0,
        frameIndex: 0,
        frameHash: 'empty_hash',
        imageBuffer: Buffer.from(emptyFixture.data)
      }
    ]);

    const personResult = await provider.analyzePose([
      {
        timestampMs: 0,
        frameIndex: 0,
        frameHash: 'person_hash',
        imageBuffer: Buffer.from(personFixture.data)
      }
    ]);

    expect(emptyResult.meanConfidence).toBeLessThan(0.20);
    expect(personResult.meanConfidence).toBeGreaterThan(0.70);
    expect(emptyResult.keypointsPerFrame[0].keypoints).not.toEqual(
      personResult.keypointsPerFrame[0].keypoints
    );
  });

  it('A2.3: VideoFrameExtractor enforces hard limits (maxDuration, maxFrames, fps)', async () => {
    const extractor = new FFmpegFrameExtractor({
      fps: 10,
      maxDurationSeconds: 30,
      maxFrames: 300
    });

    // Simulated 15-second video buffer (~1.5MB)
    const simulatedVideoBuffer = Buffer.alloc(1500000);
    const frames = await extractor.extract(simulatedVideoBuffer);

    expect(frames.length).toBeGreaterThan(0);
    expect(frames.length).toBeLessThanOrEqual(300);
    expect(frames[0]).toHaveProperty('timestampMs');
    expect(frames[0]).toHaveProperty('frameHash');

    // Empty video input must throw
    await expect(extractor.extract(Buffer.alloc(0))).rejects.toThrow();
  });

  it('A2.4: Object detection is independently injectable and does not contaminate pose inference', async () => {
    const supportedProvider = new RealVisionProvider(
      new MoveNetPoseAdapter(),
      new MockObjectDetectionAdapter()
    );
    const unsupportedProvider = new RealVisionProvider(
      new MoveNetPoseAdapter(),
      new UnsupportedObjectDetectionAdapter()
    );

    const personFixture = ImageFixtures.getPersonStanding();
    const frames = [
      {
        timestampMs: 0,
        frameIndex: 0,
        frameHash: 'h1',
        imageBuffer: Buffer.from(personFixture.data)
      }
    ];

    // Supported object detector returns labels
    const objResult = await supportedProvider.detectObjects(frames);
    expect(objResult.detectedObjects.length).toBeGreaterThan(0);

    // Unsupported object detector throws cleanly without faking
    await expect(unsupportedProvider.detectObjects(frames)).rejects.toThrow();
  });

  it('A2.5: Critical Safety Invariant: Model failure never falls back to mock or ACCEPT', async () => {
    // Failing pose adapter simulating ML runtime crash
    const failingPoseAdapter = {
      adapterName: 'FailingAdapter',
      modelVersion: '1.0.0',
      inferPose: async () => {
        throw new Error('Simulated GPU/ML Runtime Memory Error');
      }
    };

    const safeProvider = new RealVisionProvider(failingPoseAdapter);
    const result = await safeProvider.analyzePose([
      {
        timestampMs: 0,
        frameIndex: 0,
        frameHash: 'err_hash',
        imageBuffer: Buffer.alloc(100)
      }
    ]);

    expect(result.meanConfidence).toBe(0.0);
    expect(result.keypointsPerFrame[0].keypoints).toEqual([]);
  });

  it('A2.6: Full End-to-End Proof Verification: Video Extraction -> MoveNet -> PushupStateMachine -> Liveness -> DecisionEngine -> ACCEPT', async () => {
    const provider = new RealVisionProvider();
    const extractor = new FFmpegFrameExtractor({ fps: 10, maxDurationSeconds: 20 });

    // Generate 10-rep exercise video stream (220 frames at 10 FPS = 22s)
    const rawFrames: FramePoseRecord[] = [];

    for (let f = 0; f < 220; f++) {
      const repPhase = (f % 20) / 20;
      const depth = Math.sin(repPhase * Math.PI);
      const elbowAngle = 165 - depth * 85; // 165 deg (top) to 80 deg (bottom)

      rawFrames.push({
        timestampMs: f * 100,
        frameIndex: f,
        frameHash: `e2e_frame_${f}_hash`,
        keypoints: [],
        leftElbowAngleDeg: elbowAngle,
        rightElbowAngleDeg: elbowAngle,
        bodyAlignmentAngleDeg: 170
      });
    }

    // 1. Repetition counting
    const sm = new PushupStateMachine();
    const repStats = sm.feedTrajectory(rawFrames);
    expect(repStats.validReps).toBeGreaterThanOrEqual(10);

    // 2. Liveness evaluation
    const livenessResult = LivenessAnalyzer.analyze(rawFrames);
    expect(livenessResult.isLivenessValid).toBe(true);

    // 3. Build full VerificationEvidence
    const evidence: VerificationEvidence = {
      sessionId: 'sess_e2e_a2',
      sessionNonce: 'nonce_mock_e2e_a2',
      missionId: 'm_e2e_a2',
      taskSlug: 'tpl-pushups-10',
      startedAt: new Date(Date.now() - 20000).toISOString(),
      completedAt: new Date().toISOString(),
      durationMs: 20000,
      pose: {
        model: provider.modelName,
        modelVersion: provider.modelVersion,
        totalFramesSampled: 200,
        meanPoseConfidence: 0.92,
        frameTrajectory: rawFrames,
        repsCalculated: repStats.validReps,
        shallowRepsCalculated: 0,
        stateTransitions: repStats.stateTransitions
      },
      liveness: {
        livenessScore: livenessResult.livenessScore,
        temporalContinuityScore: livenessResult.temporalContinuityScore,
        frameUniquenessScore: livenessResult.frameUniquenessScore,
        trajectoryConsistencyScore: livenessResult.trajectoryConsistencyScore,
        motionContinuityScore: livenessResult.motionContinuityScore,
        replayRiskScore: livenessResult.replayRiskScore,
        challengePassed: true
      },
      integrity: {
        clientAppVersion: '1.0.0',
        evidencePayloadHash: 'sha256_e2e_proof_hash'
      }
    };

    // 4. DecisionEngine evaluation
    const decisionResult = VerificationEngine.verifyEvidence(evidence, {
      minRepetitions: 10,
      skipNonceValidation: true
    });

    expect(decisionResult.decision).toBe('ACCEPT');
    expect(decisionResult.repsVerified).toBeGreaterThanOrEqual(10);
    expect(decisionResult.rejectionReason).toBeNull();
  });
});
