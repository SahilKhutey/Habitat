// Clean Vision Provider Abstraction & Explicit Capture Context
import { Keypoint } from './evidence.types';

export interface VisionFrame {
  timestampMs: number;
  frameIndex: number;
  frameHash: string;
  width: number;
  height: number;
  data: Uint8Array | Buffer; // Raw RGB/RGBA or JPEG pixel bytes
}

export interface VisionInput {
  sessionId: string;
  taskSlug: string;
  frames: VisionFrame[];
  startedAt: number;
  endedAt?: number;
}

export interface PoseKeypointDetection {
  frameIndex: number;
  timestampMs: number;
  frameHash: string;
  keypoints: Keypoint[]; // 17 COCO keypoints (y, x, score)
  meanConfidence: number;
}

export interface PoseDetectionResult {
  model: string;
  modelVersion: string;
  provider: 'TFLite' | 'CoreML' | 'WebGPU' | 'WASM' | string;
  inputResolution: [number, number];
  framesAnalyzed: number;
  meanPoseConfidence: number;
  detections: PoseKeypointDetection[];
}

export interface ObjectDetection {
  label: string;
  confidence: number;
  boundingBox?: {
    x: number;
    y: number;
    width: number;
    height: number;
  };
}

export interface ObjectDetectionResult {
  model: string;
  modelVersion: string;
  provider: string;
  detectedObjects: ObjectDetection[];
}

export interface SceneClassification {
  sceneType: 'INDOOR_GYM' | 'OUTDOOR' | 'BEDROOM' | 'OFFICE' | string;
  confidence: number;
}

export interface IVisionProvider {
  readonly providerId: string;
  readonly modelName: string;
  readonly modelVersion: string;
  readonly providerType: 'TFLITE' | 'COREML' | 'WEBGPU' | 'MOCK';

  detectPose(input: VisionInput): Promise<PoseDetectionResult>;
  detectObjects?(input: VisionInput): Promise<ObjectDetectionResult>;
  classifyScene?(input: VisionInput): Promise<SceneClassification>;
}

// Backward compatibility alias for legacy tests
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
  }[];
}
