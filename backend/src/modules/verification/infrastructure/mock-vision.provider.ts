// Mock Vision Provider for Deterministic Offline & Unit Testing
import { FrameInput, IVisionProvider, PoseInferenceResult, ObjectInferenceResult } from '../domain/vision-provider.interface';
import { Keypoint } from '../domain/evidence.types';

export class MockVisionProvider implements IVisionProvider {
  public readonly providerId = 'mock-movenet-provider';
  public readonly modelName = 'MoveNet-Lightning-Mock';
  public readonly modelVersion = '1.0.0-mock';

  private mockKeypointsGenerator?: (frame: FrameInput) => Keypoint[];
  private mockLabels: { label: string; confidence: number }[] = [
    { label: 'person', confidence: 0.96 },
    { label: 'exercise_mat', confidence: 0.91 }
  ];

  constructor(customKeypointsGen?: (frame: FrameInput) => Keypoint[]) {
    this.mockKeypointsGenerator = customKeypointsGen;
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

  public async detectObjects(_frames: FrameInput[]): Promise<ObjectInferenceResult> {
    return {
      model: 'MockObjectDetector',
      modelVersion: '1.0.0',
      detectedLabels: this.mockLabels
    };
  }

  /**
   * Generates a 17-keypoint MoveNet payload simulating a push-up repetition cycle
   */
  private generateDefaultPushupKeypoints(frameIndex: number): Keypoint[] {
    // Sinusoidal movement cycle (period of 20 frames)
    const phase = (frameIndex % 20) / 20; // 0 to 1
    // 0 => Top (lockout), 0.5 => Bottom (deep chest to floor), 1.0 => Top
    const depthFactor = Math.sin(phase * Math.PI); // 0 at top, 1 at bottom

    // Interpolate elbow y position and shoulder-wrist geometry
    const shoulderY = 0.45 + depthFactor * 0.15;
    const elbowY = 0.40 + depthFactor * 0.20;
    const wristY = 0.60;

    return [
      { name: 'nose', x: 0.5, y: shoulderY - 0.08, score: 0.95 },
      { name: 'left_eye', x: 0.48, y: shoulderY - 0.09, score: 0.94 },
      { name: 'right_eye', x: 0.52, y: shoulderY - 0.09, score: 0.94 },
      { name: 'left_ear', x: 0.46, y: shoulderY - 0.07, score: 0.92 },
      { name: 'right_ear', x: 0.54, y: shoulderY - 0.07, score: 0.92 },
      { name: 'left_shoulder', x: 0.42, y: shoulderY, score: 0.96 },
      { name: 'right_shoulder', x: 0.58, y: shoulderY, score: 0.96 },
      { name: 'left_elbow', x: 0.38, y: elbowY, score: 0.95 },
      { name: 'right_elbow', x: 0.62, y: elbowY, score: 0.95 },
      { name: 'left_wrist', x: 0.40, y: wristY, score: 0.97 },
      { name: 'right_wrist', x: 0.60, y: wristY, score: 0.97 },
      { name: 'left_hip', x: 0.44, y: 0.55 + depthFactor * 0.08, score: 0.93 },
      { name: 'right_hip', x: 0.56, y: 0.55 + depthFactor * 0.08, score: 0.93 },
      { name: 'left_knee', x: 0.45, y: 0.70, score: 0.91 },
      { name: 'right_knee', x: 0.55, y: 0.70, score: 0.91 },
      { name: 'left_ankle', x: 0.46, y: 0.85, score: 0.90 },
      { name: 'right_ankle', x: 0.54, y: 0.85, score: 0.90 }
    ];
  }
}
