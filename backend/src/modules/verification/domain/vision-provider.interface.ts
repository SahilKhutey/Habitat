// Vision Provider Abstraction Interface
import { Keypoint } from './evidence.types';

export interface FrameInput {
  timestampMs: number;
  frameIndex: number;
  frameHash: string;
  imageBuffer?: Buffer;
  imageBase64?: string;
}

export interface PoseInferenceResult {
  model: string;
  modelVersion: string;
  framesAnalyzed: number;
  meanConfidence: number;
  keypointsPerFrame: {
    frameIndex: number;
    timestampMs: number;
    frameHash: string;
    keypoints: Keypoint[];
  }[];
}

export interface ObjectInferenceResult {
  model: string;
  modelVersion: string;
  detectedLabels: {
    label: string;
    confidence: number;
    boundingBox?: {
      x: number;
      y: number;
      width: number;
      height: number;
    };
  }[];
}

export interface IVisionProvider {
  readonly providerId: string;
  readonly modelName: string;
  readonly modelVersion: string;

  analyzePose(frames: FrameInput[]): Promise<PoseInferenceResult>;
  detectObjects?(frames: FrameInput[]): Promise<ObjectInferenceResult>;
}
