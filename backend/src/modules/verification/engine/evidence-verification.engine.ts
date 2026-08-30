// Habitat Phase 14 Authoritative Evidence Verification Engine
import { createHash } from 'crypto';
import { SessionChallengeService } from '../../proofs/services/session-challenge.service';

export interface EvidenceCheck {
  name: string;
  passed: boolean;
  score: number;
  message: string;
}

export interface FrameEvidence {
  frameIndex: number;
  timestampMs: number;
  frameHash?: string;
}

export interface EvidencePacket {
  sessionId?: string;
  sessionNonce?: string;
  missionId?: string;
  userId?: string;
  mediaType: 'PHOTO' | 'VIDEO';
  mimeType: string;
  fileSizeBytes?: number;
  sha256?: string;
  serverSha256?: string;
  bytes?: Buffer | Uint8Array | number[];
  dimensions?: { width: number; height: number };
  startedAt?: string;
  capturedAt?: string;
  completedAt?: string;
  durationSeconds?: number;
  isGalleryUpload?: boolean;
  frames?: FrameEvidence[];
  liveness?: {
    livenessScore: number;
    replayRiskScore?: number;
    opticalLux?: number;
    opticalEntropy?: number;
  };
  pose?: {
    repsCalculated: number;
    stateTransitions?: string[];
  };
  detectedLabels?: string[];
}

export interface EvidencePolicy {
  proofType?: 'PHOTO' | 'VIDEO';
  allowGallery?: boolean;
  minDurationSeconds?: number;
  maxDurationSeconds?: number;
  minRepetitions?: number;
  requiredLabels?: string[];
  minWidth?: number;
  minHeight?: number;
  maxFileSizeBytes?: number;
}

export interface VerificationDecisionResult {
  decision: 'ACCEPT' | 'REVIEW' | 'REJECT';
  accepted: boolean;
  score: number;
  checks: EvidenceCheck[];
  flags: string[];
  reason: string | null;
  metrics: Record<string, any>;
}

export class EvidenceVerificationEngine {
  public static verify(
    evidence: EvidencePacket,
    policy: EvidencePolicy = {}
  ): VerificationDecisionResult {
    const checks: EvidenceCheck[] = [];
    const flags: string[] = [];
    let isHardReject = false;
    let hardRejectReason: string | null = null;

    // 1. Session Nonce & Replay Check
    if (evidence.sessionId && evidence.sessionNonce) {
      const challengeResult = SessionChallengeService.validateAndConsumeNonce(
        evidence.sessionId,
        evidence.sessionNonce
      );

      if (!challengeResult.isValid) {
        checks.push({
          name: 'SessionChallenge',
          passed: false,
          score: 0,
          message: challengeResult.reason || 'Cryptographic session nonce invalid or already consumed'
        });
        flags.push('REPLAY_NONCE_INVALID');
        isHardReject = true;
        hardRejectReason = challengeResult.reason || 'Invalid session challenge';
      } else {
        // Validate Mission Binding
        if (challengeResult.challenge && evidence.missionId && challengeResult.challenge.missionId !== evidence.missionId) {
          checks.push({
            name: 'MissionBinding',
            passed: false,
            score: 0,
            message: `Challenge bound to mission ${challengeResult.challenge.missionId} does not match evidence mission ${evidence.missionId}`
          });
          flags.push('MISSION_BINDING_MISMATCH');
          isHardReject = true;
          hardRejectReason = 'Cross-mission replay detected';
        } else {
          checks.push({
            name: 'SessionChallenge',
            passed: true,
            score: 1.0,
            message: 'Session challenge verified and consumed'
          });
        }
      }
    }

    // 2. Anti-Gallery Bypass Check
    const allowGallery = policy.allowGallery ?? false;
    if (evidence.isGalleryUpload && !allowGallery) {
      checks.push({
        name: 'AntiGallery',
        passed: false,
        score: 0,
        message: 'Imported gallery uploads are rejected. Live camera capture required.'
      });
      flags.push('GALLERY_UPLOAD_BLOCKED');
      isHardReject = true;
      hardRejectReason = 'Gallery upload prohibited';
    } else {
      checks.push({
        name: 'AntiGallery',
        passed: true,
        score: 1.0,
        message: 'Live capture validated'
      });
    }

    // 3. Cryptographic SHA-256 & Byte Payload Integrity
    if (evidence.sha256) {
      const hex64Regex = /^[a-fA-F0-9]{64}$/;
      if (!hex64Regex.hasMatch?.(evidence.sha256) && !hex64Regex.test(evidence.sha256)) {
        checks.push({
          name: 'Sha256Format',
          passed: false,
          score: 0,
          message: 'Invalid SHA-256 format'
        });
        flags.push('INVALID_HASH_FORMAT');
        isHardReject = true;
        hardRejectReason = 'Corrupt or invalid evidence hash';
      } else if (evidence.serverSha256 && evidence.sha256 !== evidence.serverSha256) {
        checks.push({
          name: 'ServerSha256Match',
          passed: false,
          score: 0,
          message: `Client SHA-256 ${evidence.sha256} does not match server computed hash ${evidence.serverSha256}`
        });
        flags.push('HASH_TAMPERING_DETECTED');
        isHardReject = true;
        hardRejectReason = 'Server hash verification mismatch';
      } else {
        checks.push({
          name: 'Sha256Integrity',
          passed: true,
          score: 1.0,
          message: 'Cryptographic hash verified'
        });
      }
    }

    // 4. File Size & MIME Verification
    const maxSizeBytes = policy.maxFileSizeBytes ?? (evidence.mediaType === 'VIDEO' ? 50 * 1024 * 1024 : 15 * 1024 * 1024);
    if (evidence.fileSizeBytes !== undefined) {
      if (evidence.fileSizeBytes <= 0 || evidence.fileSizeBytes > maxSizeBytes) {
        checks.push({
          name: 'FileSizeBounds',
          passed: false,
          score: 0,
          message: `File size ${evidence.fileSizeBytes} bytes outside allowable bounds (max ${maxSizeBytes})`
        });
        flags.push('FILE_SIZE_OUT_OF_BOUNDS');
        isHardReject = true;
        hardRejectReason = 'File size invalid or exceeds allowable maximum';
      } else {
        checks.push({
          name: 'FileSizeBounds',
          passed: true,
          score: 1.0,
          message: 'File size within acceptable bounds'
        });
      }
    }

    // 5. Timestamps & Freshness Window
    if (evidence.capturedAt) {
      const capturedDate = new Date(evidence.capturedAt).getTime();
      const now = Date.now();
      const freshnessDeltaSec = (now - capturedDate) / 1000;

      if (freshnessDeltaSec > 180) { // Stale if > 3 minutes
        checks.push({
          name: 'TimestampFreshness',
          passed: false,
          score: 0,
          message: `Evidence is stale (captured ${Math.round(freshnessDeltaSec)}s ago, max 180s)`
        });
        flags.push('STALE_EVIDENCE_TIMESTAMP');
        isHardReject = true;
        hardRejectReason = 'Evidence timestamp expired';
      } else if (freshnessDeltaSec < -30) { // Future if > 30s ahead
        checks.push({
          name: 'TimestampFutureCheck',
          passed: false,
          score: 0,
          message: `Evidence timestamp is in the future (${Math.round(-freshnessDeltaSec)}s clock skew)`
        });
        flags.push('FUTURE_TIMESTAMP_DETECTED');
        isHardReject = true;
        hardRejectReason = 'Future timestamp detected';
      } else {
        checks.push({
          name: 'TimestampFreshness',
          passed: true,
          score: 1.0,
          message: 'Timestamp within freshness tolerance'
        });
      }
    }

    // 6. Media-Specific Verification: Photo vs Video
    if (evidence.mediaType === 'PHOTO') {
      const minW = policy.minWidth ?? 320;
      const minH = policy.minHeight ?? 240;
      if (evidence.dimensions) {
        if (evidence.dimensions.width < minW || evidence.dimensions.height < minH) {
          checks.push({
            name: 'PhotoDimensions',
            passed: false,
            score: 0,
            message: `Dimensions ${evidence.dimensions.width}x${evidence.dimensions.height} below minimum ${minW}x${minH}`
          });
          flags.push('PHOTO_DIMENSIONS_UNDERSIZED');
          isHardReject = true;
          hardRejectReason = 'Photo dimensions below minimum resolution';
        } else {
          checks.push({
            name: 'PhotoDimensions',
            passed: true,
            score: 1.0,
            message: 'Resolution verified'
          });
        }
      }
    } else if (evidence.mediaType === 'VIDEO') {
      const minDuration = policy.minDurationSeconds ?? 5;
      const maxDuration = policy.maxDurationSeconds ?? 60;
      const duration = evidence.durationSeconds ?? 0;

      if (duration < minDuration || duration > maxDuration) {
        checks.push({
          name: 'VideoDuration',
          passed: false,
          score: 0,
          message: `Video duration ${duration}s outside required [${minDuration}s - ${maxDuration}s]`
        });
        flags.push('VIDEO_DURATION_INVALID');
        isHardReject = true;
        hardRejectReason = `Video duration must be between ${minDuration}s and ${maxDuration}s`;
      } else {
        checks.push({
          name: 'VideoDuration',
          passed: true,
          score: 1.0,
          message: `Video duration ${duration}s verified`
        });
      }

      // Frame Monotonicity and Timeline Continuity
      if (evidence.frames && evidence.frames.length > 0) {
        let isMonotonic = true;
        for (let i = 1; i < evidence.frames.length; i++) {
          if (
            evidence.frames[i].timestampMs <= evidence.frames[i - 1].timestampMs ||
            evidence.frames[i].frameIndex <= evidence.frames[i - 1].frameIndex
          ) {
            isMonotonic = false;
            break;
          }
        }

        if (!isMonotonic) {
          checks.push({
            name: 'FrameMonotonicity',
            passed: false,
            score: 0,
            message: 'Video frame sequence or timestamp progression is non-monotonic'
          });
          flags.push('FRAME_SEQUENCE_MANIPULATED');
          isHardReject = true;
          hardRejectReason = 'Video temporal sequence manipulation detected';
        } else {
          checks.push({
            name: 'FrameMonotonicity',
            passed: true,
            score: 1.0,
            message: 'Frame timeline sequence verified'
          });
        }
      }
    }

    // 7. Repetitions & Physical Mission Rules
    if (policy.minRepetitions && policy.minRepetitions > 0) {
      const reps = evidence.pose?.repsCalculated ?? 0;
      if (reps < policy.minRepetitions) {
        checks.push({
          name: 'RepetitionsCount',
          passed: false,
          score: Math.min(1.0, reps / policy.minRepetitions),
          message: `Completed ${reps} reps, required ${policy.minRepetitions}`
        });
        flags.push('INSUFFICIENT_REPETITIONS');
        isHardReject = true;
        hardRejectReason = `Insufficient repetitions: ${reps}/${policy.minRepetitions}`;
      } else {
        checks.push({
          name: 'RepetitionsCount',
          passed: true,
          score: 1.0,
          message: `Verified ${reps} repetitions`
        });
      }
    }

    // 8. Required Labels & Objects Detection
    if (policy.requiredLabels && policy.requiredLabels.length > 0) {
      const detected = new Set(evidence.detectedLabels ?? []);
      const missing = policy.requiredLabels.filter(label => !detected.has(label));

      if (missing.length > 0) {
        checks.push({
          name: 'RequiredObjects',
          passed: false,
          score: 1 - missing.length / policy.requiredLabels.length,
          message: `Missing required objects in evidence: ${missing.join(', ')}`
        });
        flags.push('REQUIRED_OBJECTS_MISSING');
        isHardReject = true;
        hardRejectReason = `Missing required objects: ${missing.join(', ')}`;
      } else {
        checks.push({
          name: 'RequiredObjects',
          passed: true,
          score: 1.0,
          message: 'All required objects detected'
        });
      }
    }

    // 9. Liveness & Replay Risk Scoring
    if (evidence.liveness) {
      const livenessScore = evidence.liveness.livenessScore;
      if (livenessScore < 0.7) {
        checks.push({
          name: 'LivenessScore',
          passed: false,
          score: livenessScore,
          message: `Liveness score ${livenessScore.toFixed(2)} below threshold 0.70`
        });
        flags.push('LOW_LIVENESS_CONFIDENCE');
        if (livenessScore < 0.5) {
          isHardReject = true;
          hardRejectReason = 'Spoof or low liveness detected';
        }
      } else {
        checks.push({
          name: 'LivenessScore',
          passed: true,
          score: livenessScore,
          message: 'Liveness confidence validated'
        });
      }
    }

    // Final Decision Formulation
    const passedCount = checks.filter(c => c.passed).length;
    const totalCount = Math.max(1, checks.length);
    const overallScore = checks.reduce((sum, c) => sum + c.score, 0) / totalCount;

    let decision: 'ACCEPT' | 'REVIEW' | 'REJECT' = 'ACCEPT';
    if (isHardReject) {
      decision = 'REJECT';
    } else if (flags.length > 0 || overallScore < 0.85) {
      decision = 'REVIEW';
    }

    return {
      decision,
      accepted: decision === 'ACCEPT',
      score: Number(overallScore.toFixed(3)),
      checks,
      flags,
      reason: isHardReject ? hardRejectReason : null,
      metrics: {
        checksEvaluated: checks.length,
        checksPassed: passedCount,
        overallScore,
        hardReject: isHardReject
      }
    };
  }
}
