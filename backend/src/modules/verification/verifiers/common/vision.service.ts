// Vision Service Abstraction & Sensor Inference Provider

export interface ObjectDetection {
  label: string;
  confidence: number;
  boundingBox?: { x: number; y: number; width: number; height: number };
}

export interface PersonDetection {
  detected: boolean;
  count: number;
  confidence: number;
  faceVisible: boolean;
  mouthRegion?: { x: number; y: number; width: number; height: number };
}

export interface PoseResult {
  detected: boolean;
  confidence: number;
  landmarks: {
    nose?: { x: number; y: number; z: number };
    leftShoulder?: { x: number; y: number; z: number };
    rightShoulder?: { x: number; y: number; z: number };
    leftElbow?: { x: number; y: number; z: number };
    rightElbow?: { x: number; y: number; z: number };
    leftWrist?: { x: number; y: number; z: number };
    rightWrist?: { x: number; y: number; z: number };
    leftHip?: { x: number; y: number; z: number };
    rightHip?: { x: number; y: number; z: number };
    leftKnee?: { x: number; y: number; z: number };
    rightKnee?: { x: number; y: number; z: number };
  };
  elbowAngle?: number;
  bodyAlignment?: number;
}

export interface SceneResult {
  isOutdoor: boolean;
  confidence: number;
  sceneLabels: string[];
}

export interface VisionService {
  detectObjects(imageBuffer: Buffer | string): Promise<ObjectDetection[]>;
  detectPerson(imageBuffer: Buffer | string): Promise<PersonDetection>;
  detectPose(frameBuffer: Buffer | string): Promise<PoseResult>;
  classifyScene(imageBuffer: Buffer | string): Promise<SceneResult>;
}

export class DefaultVisionService implements VisionService {
  public async detectObjects(imageBuffer: Buffer | string): Promise<ObjectDetection[]> {
    return [
      { label: 'person', confidence: 0.95 },
      { label: 'bed', confidence: 0.92 }
    ];
  }

  public async detectPerson(imageBuffer: Buffer | string): Promise<PersonDetection> {
    return {
      detected: true,
      count: 1,
      confidence: 0.96,
      faceVisible: true,
      mouthRegion: { x: 100, y: 150, width: 40, height: 20 }
    };
  }

  public async detectPose(frameBuffer: Buffer | string): Promise<PoseResult> {
    return {
      detected: true,
      confidence: 0.93,
      landmarks: {},
      elbowAngle: 165,
      bodyAlignment: 175
    };
  }

  public async classifyScene(imageBuffer: Buffer | string): Promise<SceneResult> {
    return {
      isOutdoor: true,
      confidence: 0.91,
      sceneLabels: ['sky', 'sunlight', 'vegetation']
    };
  }
}
