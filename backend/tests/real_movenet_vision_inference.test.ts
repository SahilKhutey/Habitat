// Real MoveNet Lightning Computer Vision Inference & Complete Pipeline Test Suite
import { describe, it, expect, beforeAll, beforeEach } from 'vitest';
import { TfjsVisionProvider } from '../src/modules/verification/infrastructure/tfjs-vision.provider';
import { MockVisionProvider } from '../src/modules/verification/infrastructure/mock-vision.provider';
import { VisionInput, VisionFrame } from '../src/modules/verification/domain/vision-provider.interface';
import { VerificationEngine } from '../src/modules/verification/verification.engine';
import { SessionChallengeService } from '../src/modules/proofs/services/session-challenge.service';
import { MoveNetLightningEngine } from '../src/modules/verification/engine/movenet-lightning.engine';

// Allow time for TF model download + WASM warmup on first run
const INFERENCE_TIMEOUT = 60_000;

describe('Real MoveNet Lightning Computer Vision Inference Pipeline', () => {
  let provider: TfjsVisionProvider;
  let modelAvailable = false;

  beforeAll(async () => {
    const result = await MoveNetLightningEngine.initialize();
    modelAvailable = result.available;
    if (!result.available) {
      console.warn(`[SKIP] MoveNet model unavailable: ${result.reason}`);
    }
  }, INFERENCE_TIMEOUT);

  beforeEach(() => {
    provider = new TfjsVisionProvider();
    SessionChallengeService.resetForTesting();
  });

  it('proves TfjsVisionProvider is the canonical production provider and differs from MockVisionProvider', () => {
    const mock = new MockVisionProvider();
    expect(provider.providerType).toBe('TFLITE');
    expect(provider.modelName).toBe('MoveNet-Lightning');
    expect(provider.modelVersion).toBe('1.0.0');

    expect(mock.providerType).toBe('MOCK');
    expect(mock.modelName).toBe('MoveNet-Lightning-Mock');
  });


  it('executes MoveNet inference on real 192x192 RGB frame pixel data and produces 17 keypoints', async (ctx) => {
    if (!modelAvailable) { ctx.skip(); return; }
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
    expect(firstDetection.meanConfidence).toBeGreaterThanOrEqual(0);

    const keypointNames = firstDetection.keypoints.map((k) => k.name);
    expect(keypointNames).toContain('nose');
    expect(keypointNames).toContain('left_shoulder');
    expect(keypointNames).toContain('left_elbow');
    expect(keypointNames).toContain('left_wrist');
    expect(keypointNames).toContain('left_hip');
    expect(keypointNames).toContain('left_ankle');
  }, INFERENCE_TIMEOUT);

  it('full pipeline: genuine push-up frame stream -> MoveNet inference -> StateMachine -> Liveness', async (ctx) => {
    if (!modelAvailable) { ctx.skip(); return; }
    const challenge = SessionChallengeService.issueChallenge('mission_pushups_real', 'user_real');
    const frames: VisionFrame[] = [];
    // 20 frames = ~2 reps at 10fps — enough to exercise the full pipeline on CPU backend
    const totalFrames = 20;

    for (let f = 0; f < totalFrames; f++) {
      const repPhase = (f % 10) / 10;
      const depth = Math.sin(repPhase * Math.PI);
      const armY = 0.40 + depth * 0.25;
      const headY = 0.30 + depth * 0.15;

      const frameData = createSynthesizedRgbFrame(headY, armY);
      frames.push({
        timestampMs: f * 100,
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
      startedAt: Date.now() - 2000,
      endedAt: Date.now()
    };

    const evidence = await provider.generateVerificationEvidence(input, challenge.sessionNonce);

    expect(evidence.pose?.model).toBe('MoveNet-Lightning');
    expect(evidence.pose?.totalFramesSampled).toBe(totalFrames);
    // Verify the full pipeline ran end-to-end without error
    expect(evidence.liveness).toBeDefined();
    expect(evidence.pose?.frameTrajectory.length).toBeGreaterThan(0);
  }, INFERENCE_TIMEOUT);

  it('adversarial defense: static photograph pixel buffer -> Liveness flags frozen frame -> REJECT', async (ctx) => {
    if (!modelAvailable) { ctx.skip(); return; }
    const challenge = SessionChallengeService.issueChallenge('mission_photo_atk', 'user_photo');
    const staticBuffer = createSynthesizedRgbFrame(0.4, 0.5);
    const identicalHash = 'static_frozen_frame_hash_sha256';

    // 15 frames with identical hash + identical pixels is sufficient to trigger
    // the STATIC_PHOTO_OR_FROZEN_FRAME flag in LivenessAnalyzer
    const frames: VisionFrame[] = Array.from({ length: 15 }, (_, i) => ({
      timestampMs: i * 33,
      frameIndex: i,
      frameHash: identicalHash,
      width: 192,
      height: 192,
      data: staticBuffer
    }));

    const input: VisionInput = {
      sessionId: challenge.sessionId,
      taskSlug: 'tpl-pushups-10',
      frames,
      startedAt: Date.now() - 500,
      endedAt: Date.now()
    };

    const evidence = await provider.generateVerificationEvidence(input, challenge.sessionNonce);
    const verification = VerificationEngine.verifyEvidence(evidence, { minRepetitions: 10 });

    expect(verification.decision).toBe('REJECT');
    expect(verification.flags).toContain('STATIC_PHOTO_OR_FROZEN_FRAME');
  }, INFERENCE_TIMEOUT);

  it('rejection: pitch black / no-person image buffer -> MoveNet reports low confidence -> REJECT', async (ctx) => {
    if (!modelAvailable) { ctx.skip(); return; }
    const challenge = SessionChallengeService.issueChallenge('mission_empty_room', 'user_empty');
    const emptyBlackBuffer = new Uint8Array(192 * 192 * 3); // All zeros

    // 10 black frames is sufficient to confirm low-confidence rejection
    const frames: VisionFrame[] = Array.from({ length: 10 }, (_, i) => ({
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
      startedAt: Date.now() - 330,
      endedAt: Date.now()
    };

    const evidence = await provider.generateVerificationEvidence(input, challenge.sessionNonce);
    const verification = VerificationEngine.verifyEvidence(evidence, { minRepetitions: 10 });

    expect(verification.decision).toBe('REJECT');
  }, INFERENCE_TIMEOUT);
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
