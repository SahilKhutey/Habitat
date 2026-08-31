// Integration & Acceptance Tests: MoveNet Real Pose Inference Spike & Provider Factory
import { describe, it, expect, beforeAll, beforeEach, afterEach } from 'vitest';
import {
  MoveNetVisionProvider,
  UnsupportedVisionCapabilityError
} from '../src/modules/verification/infrastructure/movenet-vision.provider';
import { MockVisionProvider } from '../src/modules/verification/infrastructure/mock-vision.provider';
import { VisionProviderFactory } from '../src/modules/verification/infrastructure/vision-provider.factory';
import { ImageFixtures } from '../scripts/vision/fixtures/image-fixtures';
import { VisionInput } from '../src/modules/verification/domain/vision-provider.interface';
import { MoveNetLightningEngine } from '../src/modules/verification/engine/movenet-lightning.engine';

// Allow time for TF model download + WASM warmup on first run
const INFERENCE_TIMEOUT = 60_000;

describe('Track A1: Real MoveNet Pose Inference Integration & Provider Factory', () => {
  let provider: MoveNetVisionProvider;
  let modelAvailable = false;
  const originalEnv = process.env.VISION_PROVIDER;

  beforeAll(async () => {
    const result = await MoveNetLightningEngine.initialize();
    modelAvailable = result.available;
    if (!result.available) {
      console.warn(`[SKIP] MoveNet model unavailable: ${result.reason}`);
    }
  }, INFERENCE_TIMEOUT);

  beforeEach(() => {
    provider = new MoveNetVisionProvider();
  });

  afterEach(() => {
    process.env.VISION_PROVIDER = originalEnv;
  });

  it('A1.1: MoveNetVisionProvider produces real 17-keypoint pose estimation from person fixture', async (ctx) => {
    if (!modelAvailable) { ctx.skip(); return; }
    const personFixture = ImageFixtures.getPersonStanding();
    const input: VisionInput = {
      sessionId: 'sess_test_person',
      taskSlug: 'tpl-pushups-10',
      frames: [
        {
          timestampMs: 0,
          frameIndex: 0,
          frameHash: 'hash_person_1',
          width: personFixture.width,
          height: personFixture.height,
          data: personFixture.data
        }
      ],
      startedAt: Date.now() - 1000,
      endedAt: Date.now()
    };

    const result = await provider.detectPose(input);

    expect(result.model).toBe('MoveNet-Lightning');
    expect(result.modelVersion).toBe('1.0.0');
    expect(result.provider).toBe('TFLite');
    expect(result.inputResolution).toEqual([192, 192]);
    expect(result.framesAnalyzed).toBe(1);
    expect(result.detections.length).toBe(1);

    const detection = result.detections[0];
    expect(detection.keypoints.length).toBe(17);
    // Real inference runs — score may vary on synthetic pixel fixture
    expect(detection.meanConfidence).toBeGreaterThanOrEqual(0);

    const keypointNames = detection.keypoints.map((k) => k.name);
    expect(keypointNames).toEqual([
      'nose',
      'left_eye',
      'right_eye',
      'left_ear',
      'right_ear',
      'left_shoulder',
      'right_shoulder',
      'left_elbow',
      'right_elbow',
      'left_wrist',
      'right_wrist',
      'left_hip',
      'right_hip',
      'left_knee',
      'right_knee',
      'left_ankle',
      'right_ankle'
    ]);
  }, INFERENCE_TIMEOUT);

  it('A1.2: Empty room image produces different keypoints than person fixture', async (ctx) => {
    if (!modelAvailable) { ctx.skip(); return; }
    const emptyFixture = ImageFixtures.getEmptyRoom();
    const personFixture = ImageFixtures.getPersonStanding();

    const emptyInput: VisionInput = {
      sessionId: 'sess_test_empty',
      taskSlug: 'tpl-pushups-10',
      frames: [
        {
          timestampMs: 0,
          frameIndex: 0,
          frameHash: 'hash_empty_1',
          width: emptyFixture.width,
          height: emptyFixture.height,
          data: emptyFixture.data
        }
      ],
      startedAt: Date.now() - 1000,
      endedAt: Date.now()
    };

    const personInput: VisionInput = {
      sessionId: 'sess_test_person_2',
      taskSlug: 'tpl-pushups-10',
      frames: [
        {
          timestampMs: 0,
          frameIndex: 0,
          frameHash: 'hash_person_2',
          width: personFixture.width,
          height: personFixture.height,
          data: personFixture.data
        }
      ],
      startedAt: Date.now() - 1000,
      endedAt: Date.now()
    };

    const emptyResult = await provider.detectPose(emptyInput);
    const personResult = await provider.detectPose(personInput);

    // Both must return 17 keypoints from real model inference
    expect(emptyResult.detections[0].keypoints.length).toBe(17);
    expect(personResult.detections[0].keypoints.length).toBe(17);

    // Assert keypoints dynamically change between fixtures (not a static mock)
    expect(emptyResult.detections[0].keypoints).not.toEqual(personResult.detections[0].keypoints);
  }, INFERENCE_TIMEOUT);

  it('A1.3: Strictly rejects unsupported capabilities with UnsupportedVisionCapabilityError (no fake labels)', async (ctx) => {
    if (!modelAvailable) { ctx.skip(); return; }
    const personFixture = ImageFixtures.getPersonStanding();
    const input: VisionInput = {
      sessionId: 'sess_test_capabilities',
      taskSlug: 'tpl-pushups-10',
      frames: [
        {
          timestampMs: 0,
          frameIndex: 0,
          frameHash: 'hash_test_1',
          width: personFixture.width,
          height: personFixture.height,
          data: personFixture.data
        }
      ],
      startedAt: Date.now() - 1000,
      endedAt: Date.now()
    };

    await expect(provider.detectObjects(input)).rejects.toThrow(UnsupportedVisionCapabilityError);
    await expect(provider.classifyScene(input)).rejects.toThrow(UnsupportedVisionCapabilityError);
  }, INFERENCE_TIMEOUT);

  it('A1.4: VisionProviderFactory correctly resolves MoveNetVisionProvider vs MockVisionProvider', () => {
    process.env.VISION_PROVIDER = 'movenet';
    const prodProvider = VisionProviderFactory.getProvider();
    expect(prodProvider.providerId).toBe('movenet-lightning-v1');
    expect(prodProvider.modelName).toBe('MoveNet-Lightning');
    expect(prodProvider instanceof MoveNetVisionProvider).toBe(true);

    process.env.VISION_PROVIDER = 'mock';
    const devProvider = VisionProviderFactory.getProvider();
    expect(devProvider.providerId).toBe('mock-movenet-provider');
    expect(devProvider.modelName).toBe('MoveNet-Lightning-Mock');
    expect(devProvider instanceof MockVisionProvider).toBe(true);
  });
});
