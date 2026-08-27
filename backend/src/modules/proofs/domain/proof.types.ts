// Phase 6 Domain Types & Enums for Proofs and Verification

export type ProofType = 'PHOTO' | 'VIDEO' | 'MANUAL_CONFIRMATION';

export type ProofStatus =
  | 'CAPTURING'
  | 'CAPTURED'
  | 'UPLOAD_PENDING'
  | 'UPLOADING'
  | 'UPLOADED'
  | 'VALIDATING'
  | 'ACCEPTED'
  | 'REJECTED'
  | 'EXPIRED'
  | 'DELETED';

export type VerificationMode = 'BASIC' | 'RULE_BASED' | 'AI' | 'USER_REVIEW';

export type RejectionReasonCode =
  | 'INVALID_FILE'
  | 'INVALID_FORMAT'
  | 'FILE_TOO_LARGE'
  | 'VIDEO_TOO_SHORT'
  | 'VIDEO_TOO_LONG'
  | 'PHOTO_TOO_SMALL'
  | 'MISSION_NOT_ACTIVE'
  | 'PROOF_EXPIRED'
  | 'UPLOAD_INCOMPLETE'
  | 'DUPLICATE_PROOF'
  | 'INSUFFICIENT_ILLUMINATION'
  | 'INSUFFICIENT_REPETITIONS';

export interface ProofPolicy {
  type: ProofType;
  required: boolean;
  allowCamera: boolean;
  allowGallery: boolean;
  minimumDurationSeconds?: number;
  maximumDurationSeconds?: number;
  minimumPhotos?: number;
  maximumPhotos?: number;
  maxFileSizeBytes?: number;
  preferredCamera?: 'FRONT' | 'BACK';
  verificationMode?: VerificationMode;
  instructions?: string;
}

export interface MissionCompletedEvent {
  missionId: string;
  taskId: string;
  userId: string;
  completedAt: string;
  proofId: string;
  xpReward: number;
}
