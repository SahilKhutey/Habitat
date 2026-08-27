// Verification & Truth Engine Domain Types

export type VerificationStrategy =
  | 'RULE_HEURISTIC'
  | 'OBJECT_DETECTION_CV'
  | 'POSE_ESTIMATION_REPS'
  | 'AUDIO_SPECTRAL_FFT'
  | 'HYBRID_MULTI_MODAL';

export interface AntiCheatCheckResult {
  timestampFresh: boolean;
  illuminationValid: boolean;
  opticalEntropyValid: boolean;
  liveSensorStream: boolean;
  noGalleryUpload: boolean;
}

export interface VerificationEvaluationResult {
  isValid: boolean;
  strategyUsed: VerificationStrategy;
  confidenceScore: number;
  rejectionReason: string | null;
  actionableAdvice?: string;
  extractedMetrics: {
    repsCounted?: number;
    detectedObjects?: string[];
    illuminationLux?: number;
    entropyScore?: number;
    durationSec?: number;
    matchScore?: number;
  };
}

export interface TaskVerificationRule {
  minLuminanceLux?: number;
  minRepetitions?: number;
  requiredLabels?: string[];
  minDurationSeconds?: number;
  maxDurationSeconds?: number;
  minConfidenceThreshold?: number;
  allowGallery?: boolean;
}
