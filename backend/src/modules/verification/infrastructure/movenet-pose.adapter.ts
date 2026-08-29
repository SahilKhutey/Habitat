// MoveNet Pose Adapter: Translates raw frames into canonical Habitat Keypoint[] contracts
import { Keypoint } from '../domain/evidence.types';
import { FrameInput, VisionFrame } from '../domain/vision-provider.interface';
import { MoveNetLightningEngine } from '../engine/movenet-lightning.engine';

export interface IPoseAdapter {
  readonly adapterName: string;
  readonly modelVersion: string;
  inferPose(frame: FrameInput | VisionFrame): Promise<{
    keypoints: Keypoint[];
    meanConfidence: number;
    latencyMs: number;
  }>;
}

export class MoveNetPoseAdapter implements IPoseAdapter {
  public readonly adapterName = 'MoveNet-Lightning-Adapter';
  public readonly modelVersion = MoveNetLightningEngine.MODEL_VERSION;

  /**
   * Executes MoveNet inference on a single frame and maps internal representation to Keypoint[]
   */
  public async inferPose(frame: FrameInput | VisionFrame): Promise<{
    keypoints: Keypoint[];
    meanConfidence: number;
    latencyMs: number;
  }> {
    const rawData = (frame as any).data || (frame as any).imageBuffer || new Uint8Array(0);
    const width = (frame as any).width || 192;
    const height = (frame as any).height || 192;

    const inference = MoveNetLightningEngine.inferPose(rawData, width, height);

    // Map internal MoveNet points strictly to canonical Habitat Keypoint[] format
    const keypoints: Keypoint[] = inference.keypoints.map((pt) => ({
      name: pt.name,
      x: Math.round(pt.x * 10000) / 10000,
      y: Math.round(pt.y * 10000) / 10000,
      score: Math.round(pt.score * 100) / 100
    }));

    return {
      keypoints,
      meanConfidence: inference.meanConfidence,
      latencyMs: inference.inferenceLatencyMs
    };
  }
}
