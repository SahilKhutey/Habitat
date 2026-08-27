// Multi-Signal Confidence Calibration Engine
import { VerificationCheck } from '../domain/verification-reason.enum';

export class ConfidenceEngine {
  /**
   * Computes normalized overall confidence score from individual checks
   */
  public static calculateOverallConfidence(checks: VerificationCheck[]): number {
    if (!checks || checks.length === 0) return 0.50;

    let totalWeight = 0;
    let weightedScore = 0;

    for (const check of checks) {
      const weight = this.getWeightForCheck(check.name);
      totalWeight += weight;
      const score = check.passed ? Math.max(0.70, check.confidence) : Math.min(0.35, check.confidence);
      weightedScore += score * weight;
    }

    const rawConfidence = totalWeight > 0 ? weightedScore / totalWeight : 0.50;
    return Math.min(1.0, Math.max(0.0, Number(rawConfidence.toFixed(2))));
  }

  private static getWeightForCheck(name: string): number {
    switch (name) {
      case 'IMAGE_QUALITY':
        return 1.2;
      case 'PERSON_PRESENT':
        return 1.5;
      case 'REPETITION_COUNT':
        return 2.0;
      case 'OUTDOOR_SCENE':
        return 1.8;
      case 'TOOTHBRUSH_NEAR_MOUTH':
        return 1.9;
      case 'TOOTHBRUSH_PRESENT':
        return 1.4;
      default:
        return 1.0;
    }
  }
}
