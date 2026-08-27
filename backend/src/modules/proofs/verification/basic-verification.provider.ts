// Basic Verification Provider for Photo and Video Proofs
import { RejectionReasonCode } from '../domain/proof.types';

export interface ProofVerificationContext {
  proofType: 'PHOTO' | 'VIDEO' | 'MANUAL_CONFIRMATION';
  mimeType: string;
  fileSizeBytes: number;
  width?: number;
  height?: number;
  durationSeconds?: number;
  capturedAt: string;
  rules: {
    minDurationSeconds?: number;
    maxDurationSeconds?: number;
    minFileSizeBytes?: number;
    maxFileSizeBytes?: number;
    minLuminanceLux?: number;
    minRepetitions?: number;
  };
  telemetry?: {
    ambientLux?: number;
    motionCycles?: number;
  };
}

export interface BasicVerificationResult {
  status: 'ACCEPTED' | 'REJECTED';
  reasonCode: RejectionReasonCode | null;
  reasonMessage: string | null;
  confidence: number;
  checks: {
    fileValid: boolean;
    formatValid: boolean;
    durationValid: boolean;
    illuminationValid: boolean;
    repetitionsValid: boolean;
  };
}

export class BasicVerificationProvider {
  public static verify(ctx: ProofVerificationContext): BasicVerificationResult {
    const isVideo = ctx.mimeType.includes('video') || ctx.proofType === 'VIDEO';
    const isPhoto = ctx.mimeType.includes('image') || ctx.proofType === 'PHOTO';

    const checks = {
      fileValid: ctx.fileSizeBytes > 0,
      formatValid: true,
      durationValid: true,
      illuminationValid: true,
      repetitionsValid: true
    };

    // 1. File Size / Non-Zero Check
    if (ctx.fileSizeBytes <= 0) {
      return {
        status: 'REJECTED',
        reasonCode: 'INVALID_FILE',
        reasonMessage: 'Proof file is empty or corrupted.',
        confidence: 1.0,
        checks: { ...checks, fileValid: false }
      };
    }

    // 2. MIME Format Check
    const allowedPhotoMimes = ['image/jpeg', 'image/png', 'image/webp', 'image/heic'];
    const allowedVideoMimes = ['video/mp4', 'video/quicktime', 'video/webm'];

    if (isPhoto && !allowedPhotoMimes.includes(ctx.mimeType.toLowerCase()) && !isVideo) {
      return {
        status: 'REJECTED',
        reasonCode: 'INVALID_FORMAT',
        reasonMessage: `Unsupported photo format (${ctx.mimeType}). Expected JPEG, PNG, or HEIC.`,
        confidence: 1.0,
        checks: { ...checks, formatValid: false }
      };
    }

    if (isVideo && !allowedVideoMimes.includes(ctx.mimeType.toLowerCase()) && !ctx.mimeType.includes('image')) {
      return {
        status: 'REJECTED',
        reasonCode: 'INVALID_FORMAT',
        reasonMessage: `Unsupported video format (${ctx.mimeType}). Expected MP4 or QuickTime.`,
        confidence: 1.0,
        checks: { ...checks, formatValid: false }
      };
    }

    // 3. Stale Capture Check (> 3 minutes)
    if (ctx.capturedAt) {
      const captureEpoch = new Date(ctx.capturedAt).getTime();
      if (!isNaN(captureEpoch)) {
        const ageMinutes = (Date.now() - captureEpoch) / (1000 * 60);
        if (ageMinutes > 3.0) {
          return {
            status: 'REJECTED',
            reasonCode: 'PROOF_EXPIRED',
            reasonMessage: 'Proof capture is stale (> 3 minutes old). Live action required.',
            confidence: 1.0,
            checks: { ...checks, fileValid: false }
          };
        }
      }
    }

    // 4. Illumination Check (if applicable)
    if (ctx.rules.minLuminanceLux !== undefined && ctx.telemetry?.ambientLux !== undefined) {
      if (ctx.telemetry.ambientLux < ctx.rules.minLuminanceLux) {
        return {
          status: 'REJECTED',
          reasonCode: 'INSUFFICIENT_ILLUMINATION',
          reasonMessage: `Scene illumination (${ctx.telemetry.ambientLux} lux) is too dark. Minimum required: ${ctx.rules.minLuminanceLux} lux.`,
          confidence: 1.0,
          checks: { ...checks, illuminationValid: false }
        };
      }
    }

    // 5. Repetition Check (if applicable)
    if (ctx.rules.minRepetitions !== undefined && ctx.telemetry?.motionCycles !== undefined) {
      if (ctx.telemetry.motionCycles < ctx.rules.minRepetitions) {
        return {
          status: 'REJECTED',
          reasonCode: 'INSUFFICIENT_REPETITIONS',
          reasonMessage: `Insufficient repetitions detected (${ctx.telemetry.motionCycles}/${ctx.rules.minRepetitions} reps completed). Maintain full range of motion.`,
          confidence: 1.0,
          checks: { ...checks, repetitionsValid: false }
        };
      }
    }

    // 6. Video Duration Checks
    if (ctx.durationSeconds !== undefined && ctx.mimeType.includes('video')) {
      const minDuration = ctx.rules.minDurationSeconds || 5;
      const maxDuration = ctx.rules.maxDurationSeconds || 60;

      if (ctx.durationSeconds < minDuration) {
        return {
          status: 'REJECTED',
          reasonCode: 'VIDEO_TOO_SHORT',
          reasonMessage: `Video duration is ${ctx.durationSeconds}s. Minimum required is ${minDuration}s.`,
          confidence: 1.0,
          checks: { ...checks, durationValid: false }
        };
      }

      if (ctx.durationSeconds > maxDuration) {
        return {
          status: 'REJECTED',
          reasonCode: 'VIDEO_TOO_LONG',
          reasonMessage: `Video duration is ${ctx.durationSeconds}s. Maximum allowed is ${maxDuration}s.`,
          confidence: 1.0,
          checks: { ...checks, durationValid: false }
        };
      }
    }

    // All Basic Checks Passed
    return {
      status: 'ACCEPTED',
      reasonCode: null,
      reasonMessage: null,
      confidence: 1.0,
      checks
    };
  }
}
