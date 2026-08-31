// Real MoveNet Lightning SinglePose Inference Engine
// Uses @tensorflow/tfjs + @tensorflow-models/pose-detection (WASM/CPU backend)
// No native bindings required — pure JS/WASM, works on all platforms

import * as tf from '@tensorflow/tfjs';
import * as poseDetection from '@tensorflow-models/pose-detection';
import { Keypoint } from '../domain/evidence.types';

export const MOVENET_KEYPOINT_NAMES = [
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
] as const;

export type MoveNetKeypointName = typeof MOVENET_KEYPOINT_NAMES[number];

export interface MoveNetInferenceOutput {
  keypoints: Keypoint[];
  meanConfidence: number;
  inferenceLatencyMs: number;
  inputTensorShape: [number, number, number]; // [height, width, 3]
}

// Module-level singleton — detector is expensive to load, load once.
let _detector: poseDetection.PoseDetector | null = null;
let _backendInitialized = false;
let _modelAvailable = false;
let _initReason: string | undefined;

/**
 * Initialises TF.js backend (CPU) and loads MoveNet Lightning model.
 * Called once; subsequent calls return the cached result.
 * NEVER throws — returns {available: false, reason} on network or load failure.
 */
async function getDetector(): Promise<poseDetection.PoseDetector | null> {
  if (_detector) return _detector;
  if (_initReason !== undefined) return null; // already tried and failed

  try {
    if (!_backendInitialized) {
      await tf.setBackend('cpu');
      await tf.ready();
      _backendInitialized = true;
    }

    _detector = await poseDetection.createDetector(
      poseDetection.SupportedModels.MoveNet,
      {
        modelType: poseDetection.movenet.modelType.SINGLEPOSE_LIGHTNING,
        enableSmoothing: false,    // deterministic output for anti-cheat
        minPoseScore: 0.25,
      }
    );

    _modelAvailable = true;
    _initReason = 'ok';
    return _detector;
  } catch (err: any) {
    _modelAvailable = false;
    _initReason = err?.message ?? 'unknown error';
    return null;
  }
}

export class MoveNetLightningEngine {
  public static readonly MODEL_NAME = 'MoveNet-Lightning';
  public static readonly MODEL_VERSION = '1.0.0';
  public static readonly INPUT_RESOLUTION: [number, number] = [192, 192];

  /** True after a successful model download. False if network was unreachable. */
  public static get isAvailable(): boolean { return _modelAvailable; }

  /**
   * Initialises the TF.js detector. Call once during service startup.
   * Never throws — returns {available, reason} to support graceful degradation.
   */
  public static async initialize(): Promise<{ available: boolean; reason?: string }> {
    await getDetector();
    return _modelAvailable
      ? { available: true }
      : { available: false, reason: _initReason };
  }

  /**
   * Executes real MoveNet Lightning pose estimation on an RGB pixel buffer.
   * rawPixelData must be width × height × 3 bytes (RGB, no alpha).
   * Throws MoveNetUnavailableError if the model was never successfully loaded.
   */
  public static async inferPose(
    rawPixelData: Uint8Array | Buffer,
    sourceWidth: number,
    sourceHeight: number
  ): Promise<MoveNetInferenceOutput> {
    const startTime = Date.now();

    // Guard: reject empty frames immediately
    if (!rawPixelData || rawPixelData.length === 0) {
      return MoveNetLightningEngine._emptyResult(startTime);
    }

    const detector = await getDetector();

    // Model unavailable (network error during download) — return empty rather than throw,
    // so the pipeline degrades to REJECT rather than crashing the caller.
    if (!detector) {
      return MoveNetLightningEngine._emptyResult(startTime);
    }

    // Build a [H, W, 3] int32 tensor from the raw RGB buffer
    const pixelArray = new Int32Array(sourceWidth * sourceHeight * 3);
    for (let i = 0; i < pixelArray.length; i++) {
      pixelArray[i] = rawPixelData[i] ?? 0;
    }

    const imageTensor = tf.tensor3d(
      pixelArray,
      [sourceHeight, sourceWidth, 3],
      'int32'
    );

    let poses: poseDetection.Pose[];
    try {
      poses = await detector.estimatePoses(imageTensor as any, {
        maxPoses: 1,
        flipHorizontal: false,
      });
    } finally {
      imageTensor.dispose();
    }

    if (!poses || poses.length === 0) {
      return MoveNetLightningEngine._emptyResult(startTime);
    }

    const pose = poses[0];

    // Map @tensorflow-models/pose-detection Keypoint → Habitat Keypoint
    const keypoints: Keypoint[] = pose.keypoints.map((kp) => ({
      name: kp.name as MoveNetKeypointName,
      // pose-detection returns absolute pixel coords — normalise to [0,1]
      x: Math.round((kp.x / sourceWidth) * 10000) / 10000,
      y: Math.round((kp.y / sourceHeight) * 10000) / 10000,
      score: Math.round((kp.score ?? 0) * 100) / 100,
    }));

    const meanConfidence =
      keypoints.reduce((s, k) => s + k.score, 0) / Math.max(1, keypoints.length);

    return {
      keypoints,
      meanConfidence: Math.round(meanConfidence * 100) / 100,
      inferenceLatencyMs: Math.max(1, Date.now() - startTime),
      inputTensorShape: [sourceHeight, sourceWidth, 3],
    };
  }

  /** Returns an all-zero result for unprocessable frames */
  private static _emptyResult(startTime: number): MoveNetInferenceOutput {
    const emptyKeypoints: Keypoint[] = MOVENET_KEYPOINT_NAMES.map((name) => ({
      name,
      x: 0.0,
      y: 0.0,
      score: 0.0,
    }));
    return {
      keypoints: emptyKeypoints,
      meanConfidence: 0.0,
      inferenceLatencyMs: Math.max(1, Date.now() - startTime),
      inputTensorShape: [0, 0, 3],
    };
  }
}
