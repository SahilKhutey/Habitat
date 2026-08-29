// Verification Evidence Data Contracts & Types

export type MoveNetKeypointName =
  | 'nose'
  | 'left_eye'
  | 'right_eye'
  | 'left_ear'
  | 'right_ear'
  | 'left_shoulder'
  | 'right_shoulder'
  | 'left_elbow'
  | 'right_elbow'
  | 'left_wrist'
  | 'right_wrist'
  | 'left_hip'
  | 'right_hip'
  | 'left_knee'
  | 'right_knee'
  | 'left_ankle'
  | 'right_ankle';

export interface Keypoint {
  name: MoveNetKeypointName;
  x: number; // Normalized coordinate [0.0, 1.0]
  y: number; // Normalized coordinate [0.0, 1.0]
  score: number; // Detection confidence [0.0, 1.0]
}

export interface FramePoseRecord {
  timestampMs: number;
  frameIndex: number;
  frameHash: string;
  keypoints: Keypoint[];
  leftElbowAngleDeg: number;
  rightElbowAngleDeg: number;
  bodyAlignmentAngleDeg: number;
}

export interface VerificationEvidence {
  sessionId: string;
  sessionNonce: string;
  missionId: string;
  taskSlug: string;
  startedAt: string;
  completedAt: string;
  durationMs: number;

  pose: {
    model: string;
    modelVersion: string;
    totalFramesSampled: number;
    meanPoseConfidence: number;
    frameTrajectory: FramePoseRecord[];
    repsCalculated: number;
    shallowRepsCalculated: number;
    stateTransitions: string[];
  };

  liveness: {
    livenessScore: number;
    temporalContinuityScore: number;
    frameUniquenessScore: number;
    trajectoryConsistencyScore: number;
    motionContinuityScore: number;
    replayRiskScore: number;
    challengePassed?: boolean;
  };

  integrity: {
    clientAppVersion: string;
    deviceModel?: string;
    evidencePayloadHash: string;
    deviceSignature?: string;
  };
}

export interface EvidenceVerificationResult {
  decision: 'ACCEPT' | 'REVIEW' | 'REJECT';
  truthScore: number;
  repsVerified: number;
  repsRequired: number;
  livenessScore: number;
  rejectionReason: string | null;
  flags: string[];
  breakdown: {
    repetitionScore: number;
    livenessScore: number;
    formScore: number;
    integrityScore: number;
  };
}
