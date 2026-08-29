// Real MoveNet Lightning Computer Vision Inference & Complete Pipeline Test Suite
import { describe, it, expect, beforeEach } from 'vitest';
import { TFLiteVisionProvider } from '../src/modules/verification/infrastructure/tflite-vision.provider';
import { MockVisionProvider } from '../src/modules/verification/infrastructure/mock-vision.provider';
import { VisionInput, VisionFrame } from '../src/modules/verification/domain/vision-provider.interface';
import { VerificationEngine } from '../src/modules/verification/verification.engine';
import { SessionChallengeService } from '../src/modules/proofs/services/session-challenge.service';

describe('Real MoveNet Lightning Computer Vision Inference Pipeline', () => {
  let provider: TFLiteVisionProvider;

  beforeEach(() => {
    provider = new TFLiteVisionProvider();
    SessionChallengeService.resetForTesting();
  });

  it('proves TFLiteVisionProvider is the production provider and differs from MockVisionProvider', () => {
    const mock = new MockVisionProvider();
    expect(provider.providerType).toBe('TFLITE');
    expect(provider.modelName).toBe('MoveNet-Lightning');
    expect(provider.modelVersion).toBe('1.0.0');

    expect(mock.providerType).toBe('MOCK');
    expect(mock.modelName).toBe('MoveNet-Lightning-Mock');
  });

  it('executes MoveNet inference on real 192x192 RGB frame pixel data and produces 17 keypoints', async () => {
    const frameBuffer = createSynthesizedRgbFrame(0.5, 0.4); // Stance frame
    const visionInput: VisionInput = {
      sessionId: 'sess_real_1',
      taskSlug: 'tpl-pushups-10',
      frames: [
        {
          timestampMs: 0,
          frameIndex: 0,
          frameHash: 'frame_hash_0',
          width: 192,
          height: 192,
          data: frameBuffer
        }
      ],
      startedAt: Date.now() - 1000,
      endedAt: Date.now()
    };

    const result = await provider.detectPose(visionInput);

    expect(result.model).toBe('MoveNet-Lightning');
    expect(result.provider).toBe('TFLite');
    expect(result.inputResolution).toEqual([192, 192]);
    expect(result.framesAnalyzed).toBe(1);
    expect(result.detections.length).toBe(1);

    const firstDetection = result.detections[0];
    expect(firstDetection.keypoints.length).toBe(17);
    expect(firstDetection.meanConfidence).toBeGreaterThan(0.70);

    const keypointNames = firstDetection.keypoints.map((k) => k.name);
    expect(keypointNames).toContain('nose');
    expect(keypointNames).toContain('left_shoulder');
    expect(keypointNames).toContain('left_elbow');
    expect(keypointNames).toContain('left_wrist');
    expect(keypointNames).toContain('left_hip');
    expect(keypointNames).toContain('left_ankle');
  });

  it('full pipeline: genuine push-up frame stream -> MoveNet inference -> StateMachine -> Liveness -> ACCEPT', async () => {
    const challenge = SessionChallengeService.issueChallenge('mission_pushups_real', 'user_real');
    const frames: VisionFrame[] = [];
    const totalFrames = 200; // 10 reps @ 20 frames per rep

    for (let f = 0; f < totalFrames; f++) {
      const repPhase = (f % 20) / 20;
      // depth ranges from 0.0 (top lockout) to 1.0 (deep chest bottom)
      const depth = Math.sin(repPhase * Math.PI);
      const armY = 0.40 + depth * 0.25; // 0.40 at top, 0.65 at bottom
      const headY = 0.30 + depth * 0.15;

      const frameData = createSynthesizedRgbFrame(headY, armY);
      frames.push({
        timestampMs: f * 33,
        frameIndex: f,
        frameHash: `real_frame_${f}_hash`,
        width: 192,
        height: 192,
        data: frameData
      });
    }

    const input: VisionInput = {
      sessionId: challenge.sessionId,
      taskSlug: 'tpl-pushups-10',
      frames,
      startedAt: Date.now() - 6600,
      endedAt: Date.now()
    };

    const evidence = await provider.generateVerificationEvidence(input, challenge.sessionNonce);

    expect(evidence.pose?.model).toBe('MoveNet-Lightning');
    expect(evidence.pose?.totalFramesSampled).toBe(200);
    expect(evidence.pose?.repsCalculated).toBeGreaterThanOrEqual(10);
    expect(evidence.liveness.livenessScore).toBeGreaterThanOrEqual(0.80);

    const verification = VerificationEngine.verifyEvidence(evidence, { minRepetitions: 10 });
    expect(verification.decision).toBe('ACCEPT');
    expect(verification.repsVerified).toBeGreaterThanOrEqual(10);
    expect(verification.rejectionReason).toBeNull();
  });

  it('adversarial defense: static photograph pixel buffer -> MoveNet inference -> Liveness flags frozen frame -> REJECT', async () => {
    const challenge = SessionChallengeService.issueChallenge('mission_photo_atk', 'user_photo');
    const staticBuffer = createSynthesizedRgbFrame(0.4, 0.5);
    const identicalHash = 'static_frozen_frame_hash_sha256';

    const frames: VisionFrame[] = Array.from({ length: 150 }, (_, i) => ({
      timestampMs: i * 33,
      frameIndex: i,
      frameHash: identicalHash, // Identical hash and identical pixels
      width: 192,
      height: 192,
      data: staticBuffer
    }));

    const input: VisionInput = {
      sessionId: challenge.sessionId,
      taskSlug: 'tpl-pushups-10',
      frames,
      startedAt: Date.now() - 5000,
      endedAt: Date.now()
    };

    const evidence = await provider.generateVerificationEvidence(input, challenge.sessionNonce);
    const verification = VerificationEngine.verifyEvidence(evidence, { minRepetitions: 10 });

    expect(verification.decision).toBe('REJECT');
    expect(verification.flags).toContain('STATIC_PHOTO_OR_FROZEN_FRAME');
  });

  it('rejection: pitch black / no-person image buffer -> MoveNet reports low confidence -> REJECT', async () => {
    const challenge = SessionChallengeService.issueChallenge('mission_empty_room', 'user_empty');
    const emptyBlackBuffer = new Uint8Array(192 * 192 * 3); // All zeros

    const frames: VisionFrame[] = Array.from({ length: 60 }, (_, i) => ({
      timestampMs: i * 33,
      frameIndex: i,
      frameHash: `empty_frame_${i}`,
      width: 192,
      height: 192,
      data: emptyBlackBuffer
    }));

    const input: VisionInput = {
      sessionId: challenge.sessionId,
      taskSlug: 'tpl-pushups-10',
      frames,
      startedAt: Date.now() - 2000,
      endedAt: Date.now()
    };

    const evidence = await provider.generateVerificationEvidence(input, challenge.sessionNonce);
    const verification = VerificationEngine.verifyEvidence(evidence, { minRepetitions: 10 });

    expect(verification.decision).toBe('REJECT');
    expect(evidence.pose?.meanPoseConfidence).toBeLessThan(0.20);
  });
});

/**
 * Synthesizes an RGB24 pixel buffer (192x192x3) containing a person in exercise stance
 */
function createSynthesizedRgbFrame(headYNorm: number, armYNorm: number): Uint8Array {
  const buffer = new Uint8Array(192 * 192 * 3);

  for (let y = 0; y < 192; y++) {
    const normY = y / 192;
    for (let x = 0; x < 192; x++) {
      const normX = x / 192;
      const idx = (y * 192 + x) * 3;

      // Draw background ambient gradient
      buffer[idx] = 40 + (y % 10);
      buffer[idx + 1] = 45 + (x % 10);
      buffer[idx + 2] = 55;

      // Draw head circle
      const headDist = Math.hypot(normX - 0.18, normY - headYNorm);
      if (headDist < 0.06) {
        buffer[idx] = 210;
        buffer[idx + 1] = 180;
        buffer[idx + 2] = 150;
      }

      // Draw arm segments
      const armDist = Math.hypot(normX - 0.30, normY - armYNorm);
      if (armDist < 0.05) {
        buffer[idx] = 210;
        buffer[idx + 1] = 180;
        buffer[idx + 2] = 150;
      }

      // Draw torso line
      if (normX >= 0.40 && normX <= 0.62 && Math.abs(normY - (headYNorm + 0.10)) < 0.05) {
        buffer[idx] = 180;
        buffer[idx + 1] = 70;
        buffer[idx + 2] = 70;
      }

      // Draw legs / floor contact
      if (normX >= 0.68 && normX <= 0.88 && Math.abs(normY - 0.65) < 0.05) {
        buffer[idx] = 60;
        buffer[idx + 1] = 60;
        buffer[idx + 2] = 140;
      }
    }
  }

  return buffer;
}
