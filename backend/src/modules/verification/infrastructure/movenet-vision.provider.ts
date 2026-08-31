// MoveNet Vision Provider with Strict Capability Boundaries
import {
  IVisionProvider,
  VisionInput,
  PoseDetectionResult,
  ObjectDetectionResult,
  SceneClassification,
  PoseKeypointDetection
} from '../domain/vision-provider.interface';
import { MoveNetLightningEngine } from '../engine/movenet-lightning.engine';

export class UnsupportedVisionCapabilityError extends Error {
  public readonly capability: string;

  constructor(capability: string, message?: string) {
    super(
      message ||
        `Vision capability '${capability}' is not supported by MoveNetVisionProvider. MoveNet is a specialized pose estimation model; object detection and scene classification require distinct vision providers.`
    );
    this.name = 'UnsupportedVisionCapabilityError';
    this.capability = capability;
  }
}

export class MoveNetVisionProvider implements IVisionProvider {
  public readonly providerId = 'movenet-lightning-v1';
  public readonly modelName = MoveNetLightningEngine.MODEL_NAME;
  public readonly modelVersion = MoveNetLightningEngine.MODEL_VERSION;
  public readonly providerType = 'TFLITE' as const;

  /**
   * Executes real MoveNet Lightning 17-keypoint pose estimation
   */
  public async detectPose(input: VisionInput): Promise<PoseDetectionResult> {
    const detections: PoseKeypointDetection[] = [];
    let totalConfidence = 0;

    for (const frame of input.frames) {
      const inference = await MoveNetLightningEngine.inferPose(
        frame.data,
        frame.width || 192,
        frame.height || 192
      );

      detections.push({
        frameIndex: frame.frameIndex,
        timestampMs: frame.timestampMs,
        frameHash: frame.frameHash,
        keypoints: inference.keypoints,
        meanConfidence: inference.meanConfidence
      });

      totalConfidence += inference.meanConfidence;
    }

    const meanPoseConfidence =
      detections.length > 0 ? totalConfidence / detections.length : 0.0;

    return {
      model: this.modelName,
      modelVersion: this.modelVersion,
      provider: 'TFLite',
      inputResolution: MoveNetLightningEngine.INPUT_RESOLUTION,
      framesAnalyzed: input.frames.length,
      meanPoseConfidence: Math.round(meanPoseConfidence * 100) / 100,
      detections
    };
  }

  /**
   * Strictly honest capability boundary: Does NOT return fake mock labels
   */
  public async detectObjects(_input: VisionInput): Promise<ObjectDetectionResult> {
    throw new UnsupportedVisionCapabilityError('OBJECT_DETECTION');
  }

  /**
   * Strictly honest capability boundary: Does NOT return fake scene labels
   */
  public async classifyScene(_input: VisionInput): Promise<SceneClassification> {
    throw new UnsupportedVisionCapabilityError('SCENE_CLASSIFICATION');
  }
}
