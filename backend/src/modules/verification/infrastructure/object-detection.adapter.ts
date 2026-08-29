// Object Detection Adapter Abstraction
import { FrameInput, VisionFrame, ObjectDetection } from '../domain/vision-provider.interface';

export interface IObjectDetectionAdapter {
  readonly adapterName: string;
  readonly isSupported: boolean;
  detectObjects(frames: (FrameInput | VisionFrame)[]): Promise<ObjectDetection[]>;
}

export class UnsupportedObjectDetectionAdapter implements IObjectDetectionAdapter {
  public readonly adapterName = 'Unsupported-Object-Detector';
  public readonly isSupported = false;

  public async detectObjects(_frames: (FrameInput | VisionFrame)[]): Promise<ObjectDetection[]> {
    throw new Error(
      'Object detection is not supported by this deployment configuration. Set VISION_OBJECT_PROVIDER to a supported provider.'
    );
  }
}

export class MockObjectDetectionAdapter implements IObjectDetectionAdapter {
  public readonly adapterName = 'Mock-Object-Detector';
  public readonly isSupported = true;

  public async detectObjects(_frames: (FrameInput | VisionFrame)[]): Promise<ObjectDetection[]> {
    return [
      { label: 'person', confidence: 0.95 },
      { label: 'exercise_mat', confidence: 0.90 }
    ];
  }
}
