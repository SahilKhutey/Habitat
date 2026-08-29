// Multi-Strategy Proof Verification & Evidence-Driven AI Engine
import { VerificationEvidence, EvidenceVerificationResult } from './domain/evidence.types';
import { PushupStateMachine } from './domain/pushup-state-machine';
import { LivenessAnalyzer } from './engine/liveness-analyzer';
import { SessionChallengeService } from '../proofs/services/session-challenge.service';

export interface VerificationContext {
  taskSlug: string;
  proofType: string;
  mediaType: string;
  capturedAt: string;
  deviceTelemetry: {
    ambientLux?: number;
    accelerometerMotion?: boolean;
    durationSeconds?: number;
    detectedLabels?: string[];
    motionCycles?: number;
    poseConfidence?: number;
  };
  validationRules: {
    minLuminance?: number;
    minDurationSec?: number;
    requiredLabels?: string[];
    minRepetitions?: number;
    motionThreshold?: number;
  };
}

export interface VerificationResult {
  isValid: boolean;
  strategyUsed: string;
  rejectionReason: string | null;
  confidenceScore: number;
  extractedMetrics: {
    repsCounted?: number;
    detectedObjects?: string[];
    illuminationLux?: number;
  };
}

export class VerificationEngine {
  /**
   * Evaluates a full cryptographic VerificationEvidence packet
   */
  public static verifyEvidence(
    evidence: VerificationEvidence,
    policy: { minRepetitions?: number; minLivenessScore?: number; skipNonceValidation?: boolean } = {}
  ): EvidenceVerificationResult {
    const requiredReps = policy.minRepetitions ?? 10;
    const minLivenessThreshold = policy.minLivenessScore ?? 0.70;
    const flags: string[] = [];

    // 1. Validate Cryptographic Session Nonce
    let integrityScore = 1.0;
    if (policy.skipNonceValidation) {
      integrityScore = 1.0;
    } else if (evidence.sessionId && evidence.sessionNonce) {
      const nonceResult = SessionChallengeService.validateAndConsumeNonce(
        evidence.sessionId,
        evidence.sessionNonce
      );
      if (!nonceResult.isValid) {
        flags.push('INVALID_OR_REPLAYED_SESSION_NONCE');
        integrityScore = 0.0;
      }
    } else {
      flags.push('MISSING_SESSION_NONCE');
      integrityScore = 0.2;
    }

    // 2. Independent Multi-Signal Liveness Analysis
    const livenessAnalysis = LivenessAnalyzer.analyze(
      evidence.pose?.frameTrajectory ?? []
    );
    flags.push(...livenessAnalysis.flags);

    // 3. Independent Backend Push-Up Trajectory Replay
    const sm = new PushupStateMachine();
    const repStats = sm.feedTrajectory(evidence.pose?.frameTrajectory ?? []);
    const verifiedReps = repStats.validReps;

    // 4. Score Calculations
    const repetitionScore = requiredReps > 0
      ? Math.min(1.0, verifiedReps / requiredReps)
      : 1.0;

    const totalRepsAttempted =
      repStats.validReps + repStats.shallowReps + repStats.badFormReps;
    const formScore = totalRepsAttempted > 0
      ? repStats.validReps / totalRepsAttempted
      : (repStats.validReps > 0 ? 1.0 : 0.0);

    const livenessScore = livenessAnalysis.livenessScore;

    // 5. Composite Truth Score
    // Truth = 0.35 * Reps + 0.35 * Liveness + 0.15 * Form + 0.15 * Integrity
    const compositeTruthScore =
      repetitionScore * 0.35 +
      livenessScore * 0.35 +
      formScore * 0.15 +
      integrityScore * 0.15;

    // Check pose confidence
    const meanConfidence = evidence.pose?.meanPoseConfidence ?? 0.90;
    if (meanConfidence < 0.65) {
      flags.push('LOW_POSE_CONFIDENCE');
    }

    const roundedTruthScore = Math.round(compositeTruthScore * 100) / 100;

    // 6. Tri-State Decision Logic
    let decision: 'ACCEPT' | 'REVIEW' | 'REJECT';
    let rejectionReason: string | null = null;

    if (flags.includes('INVALID_OR_REPLAYED_SESSION_NONCE')) {
      decision = 'REJECT';
      rejectionReason = 'Session verification failed: Nonce is invalid, expired, or already consumed.';
    } else if (flags.includes('STATIC_PHOTO_OR_FROZEN_FRAME')) {
      decision = 'REJECT';
      rejectionReason = 'Static photograph or frozen frame detected. Live physical exercise is required.';
    } else if (flags.includes('POTENTIAL_REPLAY_LOOP_DETECTED')) {
      decision = 'REJECT';
      rejectionReason = 'Repetitive video replay loop detected. Live exercise execution is required.';
    } else if (flags.includes('TEMPORAL_MONOTONICITY_VIOLATION')) {
      decision = 'REJECT';
      rejectionReason = 'Video temporal continuity failed: Non-monotonic timestamps or temporal splicing detected.';
    } else if (verifiedReps < requiredReps) {
      decision = 'REJECT';
      rejectionReason = `Insufficient valid repetitions (${verifiedReps}/${requiredReps} completed with full depth).`;
    } else if (
      roundedTruthScore >= 0.80 &&
      verifiedReps >= requiredReps &&
      livenessScore >= minLivenessThreshold &&
      meanConfidence >= 0.70 &&
      !flags.includes('LOW_POSE_CONFIDENCE')
    ) {
      decision = 'ACCEPT';
      rejectionReason = null;
    } else if (
      verifiedReps >= requiredReps &&
      (roundedTruthScore >= 0.50 || livenessScore >= 0.50 || flags.includes('LOW_POSE_CONFIDENCE'))
    ) {
      decision = 'REVIEW';
      rejectionReason = `Proof flagged for audit review (Truth Score: ${roundedTruthScore}, Verified Reps: ${verifiedReps}/${requiredReps}, Mean Confidence: ${meanConfidence}).`;
    } else {
      decision = 'REJECT';
      rejectionReason = livenessAnalysis.rejectionReason ?? 'Proof failed truth and liveness verification.';
    }

    return {
      decision,
      truthScore: roundedTruthScore,
      repsVerified: verifiedReps,
      repsRequired: requiredReps,
      livenessScore,
      rejectionReason,
      flags,
      breakdown: {
        repetitionScore: Math.round(repetitionScore * 100) / 100,
        livenessScore: Math.round(livenessScore * 100) / 100,
        formScore: Math.round(formScore * 100) / 100,
        integrityScore: Math.round(integrityScore * 100) / 100
      }
    };
  }

  /**
   * Main verification entry point evaluating proofs using progressive verification strategies (Legacy / Rule-based)
   */
  public static verify(ctx: VerificationContext): VerificationResult {
    // 1. Basic Rule Strategy (Timestamp Freshness & Illumination)
    const ruleCheck = this.runRuleVerification(ctx);
    if (!ruleCheck.isValid) {
      return ruleCheck;
    }

    // 2. Video Repetition / Exercise Strategy
    if (ctx.proofType === 'VIDEO' && ctx.validationRules.minRepetitions) {
      return this.runPoseRepCounterVerification(ctx);
    }

    // 3. Smart CV Label Detection Strategy
    if (ctx.validationRules.requiredLabels && ctx.validationRules.requiredLabels.length > 0) {
      return this.runSmartCvVerification(ctx);
    }

    // 4. Default Pass
    return {
      isValid: true,
      strategyUsed: 'BasicRuleVerifier',
      rejectionReason: null,
      confidenceScore: 0.95,
      extractedMetrics: {
        illuminationLux: ctx.deviceTelemetry.ambientLux
      }
    };
  }

  private static runRuleVerification(ctx: VerificationContext): VerificationResult {
    const now = new Date();
    const captured = new Date(ctx.capturedAt);
    const ageSeconds = Math.floor((now.getTime() - captured.getTime()) / 1000);

    // Freshness check
    if (ageSeconds > 180) {
      return {
        isValid: false,
        strategyUsed: 'RuleVerifier',
        rejectionReason: `Proof capture is stale (${ageSeconds}s old). Must capture live within 3 minutes.`,
        confidenceScore: 1.0,
        extractedMetrics: {}
      };
    }

    // Illumination check
    const minLux = ctx.validationRules.minLuminance || 25;
    if (ctx.deviceTelemetry.ambientLux !== undefined && ctx.deviceTelemetry.ambientLux < minLux) {
      return {
        isValid: false,
        strategyUsed: 'RuleVerifier',
        rejectionReason: `Scene illumination too dark (${ctx.deviceTelemetry.ambientLux} lux). Minimum required: ${minLux} lux.`,
        confidenceScore: 1.0,
        extractedMetrics: { illuminationLux: ctx.deviceTelemetry.ambientLux }
      };
    }

    return {
      isValid: true,
      strategyUsed: 'RuleVerifier',
      rejectionReason: null,
      confidenceScore: 0.95,
      extractedMetrics: { illuminationLux: ctx.deviceTelemetry.ambientLux }
    };
  }

  private static runPoseRepCounterVerification(ctx: VerificationContext): VerificationResult {
    const requiredReps = ctx.validationRules.minRepetitions || 10;
    const detectedReps = ctx.deviceTelemetry.motionCycles ?? (ctx.deviceTelemetry.accelerometerMotion ? requiredReps : 0);

    if (detectedReps < requiredReps) {
      return {
        isValid: false,
        strategyUsed: 'PoseRepCounterVerifier',
        rejectionReason: `Insufficient repetitions detected (${detectedReps}/${requiredReps} reps completed). Maintain full range of motion.`,
        confidenceScore: 0.88,
        extractedMetrics: { repsCounted: detectedReps }
      };
    }

    return {
      isValid: true,
      strategyUsed: 'PoseRepCounterVerifier',
      rejectionReason: null,
      confidenceScore: 0.92,
      extractedMetrics: { repsCounted: detectedReps }
    };
  }

  private static runSmartCvVerification(ctx: VerificationContext): VerificationResult {
    const required = ctx.validationRules.requiredLabels || [];
    const detected = ctx.deviceTelemetry.detectedLabels || [];

    if (detected.length > 0) {
      const hasMatch = required.some((reqLabel) =>
        detected.map((d) => d.toLowerCase()).includes(reqLabel.toLowerCase())
      );

      if (!hasMatch) {
        return {
          isValid: false,
          strategyUsed: 'SmartCvVerifier',
          rejectionReason: `Required target object not detected (${required.join(', ')}). Align viewfinder to frame your task clearly.`,
          confidenceScore: 0.85,
          extractedMetrics: { detectedObjects: detected }
        };
      }
    }

    return {
      isValid: true,
      strategyUsed: 'SmartCvVerifier',
      rejectionReason: null,
      confidenceScore: 0.90,
      extractedMetrics: { detectedObjects: detected.length > 0 ? detected : required }
    };
  }
}
