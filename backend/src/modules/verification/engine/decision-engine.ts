// Decision Engine with Tri-State Thresholds (ACCEPT / REVIEW / REJECT)
import { VerificationDecision } from '../domain/verification-status.enum';
import { VerificationCheck, VerificationReason } from '../domain/verification-reason.enum';

export interface DecisionPolicy {
  acceptThreshold: number; // e.g. 0.85
  rejectThreshold: number; // e.g. 0.50
}

export const defaultDecisionPolicy: DecisionPolicy = {
  acceptThreshold: 0.80,
  rejectThreshold: 0.50
};

export class DecisionEngine {
  /**
   * Evaluates checks and confidence score to render authoritative decision
   */
  public static decide(
    confidence: number,
    checks: VerificationCheck[],
    reasons: VerificationReason[],
    policy: DecisionPolicy = defaultDecisionPolicy
  ): {
    decision: VerificationDecision;
    confidence: number;
    explanation: string;
  } {
    const allPassed = checks.every((c) => c.passed);

    // If critical failure reasons exist, reject immediately
    if (reasons.length > 0 && !allPassed) {
      if (confidence < policy.rejectThreshold) {
        return {
          decision: VerificationDecision.REJECT,
          confidence,
          explanation: `Proof rejected due to: ${reasons.join(', ')}`
        };
      } else {
        // Intermediate confidence with failure reasons goes to review
        return {
          decision: VerificationDecision.REVIEW,
          confidence,
          explanation: `Ambiguous evidence detected (${reasons.join(', ')}). Queued for verification review.`
        };
      }
    }

    if (confidence >= policy.acceptThreshold && allPassed) {
      return {
        decision: VerificationDecision.ACCEPT,
        confidence,
        explanation: 'All task verification checks passed with high confidence.'
      };
    } else if (confidence <= policy.rejectThreshold) {
      return {
        decision: VerificationDecision.REJECT,
        confidence,
        explanation: 'Confidence below required verification threshold.'
      };
    } else {
      return {
        decision: VerificationDecision.REVIEW,
        confidence,
        explanation: 'Verification confidence is in review band.'
      };
    }
  }
}
