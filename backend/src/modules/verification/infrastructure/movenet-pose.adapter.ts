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
   * Executes real MoveNet Lightning inference on a single frame.
   * Frame must carry an imageBuffer with raw RGB (or RGBA) pixel data.
   */
  public async inferPose(frame: FrameInput | VisionFrame): Promise<{
    keypoints: Keypoint[];
    meanConfidence: number;
    latencyMs: number;
  }> {
    const rawData: Uint8Array | Buffer =
      (frame as any).imageBuffer ||
      (frame as any).data ||
      new Uint8Array(0);

    const width: number = (frame as any).width || 192;
    const height: number = (frame as any).height || 192;

    const inference = await MoveNetLightningEngine.inferPose(rawData, width, height);

    return {
      keypoints: inference.keypoints,
      meanConfidence: inference.meanConfidence,
      latencyMs: inference.inferenceLatencyMs,
    };
  }
}
