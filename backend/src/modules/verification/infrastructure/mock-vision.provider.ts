// Mock Vision Provider for Deterministic Offline & Unit Testing
import {
  IVisionProvider,
  VisionInput,
  PoseDetectionResult,
  ObjectDetectionResult,
  FrameInput,
  PoseInferenceResult
} from '../domain/vision-provider.interface';
import { Keypoint } from '../domain/evidence.types';

export class MockVisionProvider implements IVisionProvider {
  public readonly providerId = 'mock-movenet-provider';
  public readonly modelName = 'MoveNet-Lightning-Mock';
  public readonly modelVersion = '1.0.0-mock';
  public readonly providerType = 'MOCK' as const;

  private mockKeypointsGenerator?: (frame: any) => Keypoint[];
  private mockLabels: { label: string; confidence: number }[] = [
    { label: 'person', confidence: 0.96 },
    { label: 'exercise_mat', confidence: 0.91 }
  ];

  constructor(customKeypointsGen?: (frame: any) => Keypoint[]) {
    this.mockKeypointsGenerator = customKeypointsGen;
  }

  public async detectPose(input: VisionInput): Promise<PoseDetectionResult> {
    const detections = input.frames.map((frame) => {
      const keypoints = this.mockKeypointsGenerator
        ? this.mockKeypointsGenerator(frame)
        : this.generateDefaultPushupKeypoints(frame.frameIndex);

      const meanConfidence =
        keypoints.reduce((acc, kp) => acc + kp.score, 0) / Math.max(1, keypoints.length);

      return {
        frameIndex: frame.frameIndex,
        timestampMs: frame.timestampMs,
        frameHash: frame.frameHash,
        keypoints,
        meanConfidence
      };
    });

    const overallMeanConfidence =
      detections.reduce((acc, d) => acc + d.meanConfidence, 0) / Math.max(1, detections.length);

    return {
      model: this.modelName,
      modelVersion: this.modelVersion,
      provider: 'WASM',
      inputResolution: [192, 192],
      framesAnalyzed: input.frames.length,
      meanPoseConfidence: overallMeanConfidence,
      detections
    };
  }

  public async analyzePose(frames: FrameInput[]): Promise<PoseInferenceResult> {
    const results = frames.map((frame) => {
      const keypoints = this.mockKeypointsGenerator
        ? this.mockKeypointsGenerator(frame)
        : this.generateDefaultPushupKeypoints(frame.frameIndex);

      return {
        frameIndex: frame.frameIndex,
        timestampMs: frame.timestampMs,
        frameHash: frame.frameHash,
        keypoints
      };
    });

    return {
      model: this.modelName,
      modelVersion: this.modelVersion,
      framesAnalyzed: frames.length,
      meanConfidence: 0.94,
      keypointsPerFrame: results
    };
  }

  public async detectObjects(_input: any): Promise<any> {
    return {
      model: 'MockObjectDetector',
      modelVersion: '1.0.0',
      provider: 'MOCK',
      detectedObjects: this.mockLabels.map((l) => ({ label: l.label, confidence: l.confidence })),
      detectedLabels: this.mockLabels
    };
  }

  /**
   * Generates a 17-keypoint MoveNet payload simulating a push-up repetition cycle
   */
  private generateDefaultPushupKeypoints(frameIndex: number): Keypoint[] {
    const phase = (frameIndex % 20) / 20;
    const depthFactor = Math.sin(phase * Math.PI);
    const elbowY = 0.50 + depthFactor * 0.18;

    return [
      { name: 'nose', x: 0.20, y: 0.35 + depthFactor * 0.15, score: 0.96 },
      { name: 'left_eye', x: 0.21, y: 0.33 + depthFactor * 0.15, score: 0.95 },
      { name: 'right_eye', x: 0.21, y: 0.37 + depthFactor * 0.15, score: 0.95 },
      { name: 'left_ear', x: 0.24, y: 0.32 + depthFactor * 0.15, score: 0.92 },
      { name: 'right_ear', x: 0.24, y: 0.38 + depthFactor * 0.15, score: 0.92 },
      { name: 'left_shoulder', x: 0.30, y: 0.40 + depthFactor * 0.15, score: 0.97 },
      { name: 'right_shoulder', x: 0.30, y: 0.45 + depthFactor * 0.15, score: 0.97 },
      { name: 'left_elbow', x: 0.28, y: elbowY, score: 0.94 },
      { name: 'right_elbow', x: 0.28, y: elbowY, score: 0.94 },
      { name: 'left_wrist', x: 0.30, y: 0.70, score: 0.96 },
      { name: 'right_wrist', x: 0.30, y: 0.70, score: 0.96 },
      { name: 'left_hip', x: 0.55, y: 0.42 + depthFactor * 0.12, score: 0.95 },
      { name: 'right_hip', x: 0.55, y: 0.46 + depthFactor * 0.12, score: 0.95 },
      { name: 'left_knee', x: 0.75, y: 0.48 + depthFactor * 0.08, score: 0.93 },
      { name: 'right_knee', x: 0.75, y: 0.52 + depthFactor * 0.08, score: 0.93 },
      { name: 'left_ankle', x: 0.90, y: 0.65, score: 0.96 },
      { name: 'right_ankle', x: 0.90, y: 0.65, score: 0.96 }
    ];
  }
}
