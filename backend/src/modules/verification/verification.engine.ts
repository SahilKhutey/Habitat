// Multi-Strategy Proof Verification & AI Engine
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
   * Main verification entry point evaluating proofs using progressive verification strategies
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

    // If telemetry provided detectedLabels, verify presence
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
