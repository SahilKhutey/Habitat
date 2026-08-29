// Verification Confusion Matrix Evaluator & Release Gate Invariant Checker
import { VerificationEngine } from '../../src/modules/verification/verification.engine';
import { VisionFixtureGenerator } from '../fixtures/vision_fixture_generator';
import { AdversarialFixtureGenerator } from '../fixtures/adversarial_fixture_generator';

export interface ConfusionMatrixResult {
  valid: { accept: number; review: number; reject: number; total: number };
  ambiguous: { accept: number; review: number; reject: number; total: number };
  spoof: { accept: number; review: number; reject: number; total: number };
  totalEvaluations: number;
  trueAcceptRate: number;
  falseAcceptRate: number;
  falseRejectRate: number;
  spoofAcceptedCount: number;
  passedReleaseGate: boolean;
}

export class ConfusionMatrixEvaluator {
  public static evaluateAll(): ConfusionMatrixResult {
    const validFixtures = VisionFixtureGenerator.getValidFixtures();
    const invalidFixtures = VisionFixtureGenerator.getInvalidFixtures();
    const ambiguousFixtures = VisionFixtureGenerator.getAmbiguousFixtures();
    const adversarialFixtures = AdversarialFixtureGenerator.getAllAdversarialAttacks();

    const matrix = {
      valid: { accept: 0, review: 0, reject: 0, total: 0 },
      ambiguous: { accept: 0, review: 0, reject: 0, total: 0 },
      spoof: { accept: 0, review: 0, reject: 0, total: 0 }
    };

    // 1. Evaluate Valid Fixtures
    for (const fixture of validFixtures) {
      matrix.valid.total++;
      const result = VerificationEngine.verifyEvidence(fixture.evidence, {
        minRepetitions: fixture.minimumExpectedReps ?? 10,
        skipNonceValidation: true
      });
      if (result.decision === 'ACCEPT') matrix.valid.accept++;
      else if (result.decision === 'REVIEW') matrix.valid.review++;
      else matrix.valid.reject++;
    }

    // 2. Evaluate Invalid (Non-Spoof) Fixtures
    for (const fixture of invalidFixtures) {
      matrix.valid.total++;
      const result = VerificationEngine.verifyEvidence(fixture.evidence, {
        minRepetitions: fixture.minimumExpectedReps ?? 10,
        skipNonceValidation: true
      });
      if (result.decision === 'ACCEPT') matrix.valid.accept++;
      else if (result.decision === 'REVIEW') matrix.valid.review++;
      else matrix.valid.reject++;
    }

    // 3. Evaluate Ambiguous Fixtures
    for (const fixture of ambiguousFixtures) {
      matrix.ambiguous.total++;
      const result = VerificationEngine.verifyEvidence(fixture.evidence, {
        minRepetitions: fixture.minimumExpectedReps ?? 10,
        skipNonceValidation: true
      });
      if (result.decision === 'ACCEPT') matrix.ambiguous.accept++;
      else if (result.decision === 'REVIEW') matrix.ambiguous.review++;
      else matrix.ambiguous.reject++;
    }

    // 4. Evaluate Adversarial Spoof Fixtures
    for (const fixture of adversarialFixtures) {
      matrix.spoof.total++;
      const result = VerificationEngine.verifyEvidence(fixture.evidence, {
        minRepetitions: 10,
        skipNonceValidation: true
      });
      if (result.decision === 'ACCEPT') matrix.spoof.accept++;
      else if (result.decision === 'REVIEW') matrix.spoof.review++;
      else matrix.spoof.reject++;
    }

    const totalEvaluations = matrix.valid.total + matrix.ambiguous.total + matrix.spoof.total;
    const trueAcceptRate = validFixtures.length > 0 ? matrix.valid.accept / validFixtures.length : 1.0;
    const falseAcceptRate = matrix.spoof.total > 0 ? matrix.spoof.accept / matrix.spoof.total : 0.0;
    const falseRejectRate = validFixtures.length > 0 ? matrix.valid.reject / validFixtures.length : 0.0;
    const spoofAcceptedCount = matrix.spoof.accept;
    const passedReleaseGate = spoofAcceptedCount === 0;

    return {
      valid: matrix.valid,
      ambiguous: matrix.ambiguous,
      spoof: matrix.spoof,
      totalEvaluations,
      trueAcceptRate,
      falseAcceptRate,
      falseRejectRate,
      spoofAcceptedCount,
      passedReleaseGate
    };
  }

  public static getFormattedScorecard(result: ConfusionMatrixResult): string {
    return `
================================================================================
                    HABITAT VERIFICATION QUALITY SCORECARD
================================================================================
Total Evaluations: ${result.totalEvaluations}
True Accept Rate (TAR):  ${(result.trueAcceptRate * 100).toFixed(1)}%
False Accept Rate (FAR): ${(result.falseAcceptRate * 100).toFixed(1)}%
False Reject Rate (FRR): ${(result.falseRejectRate * 100).toFixed(1)}%

CONFUSION MATRIX:
--------------------------------------------------------------------------------
Actual Category     | System ACCEPT | System REVIEW | System REJECT | Total
--------------------------------------------------------------------------------
Valid Genuine       | ${result.valid.accept.toString().padEnd(13)} | ${result.valid.review.toString().padEnd(13)} | ${result.valid.reject.toString().padEnd(13)} | ${result.valid.total}
Ambiguous / Edge    | ${result.ambiguous.accept.toString().padEnd(13)} | ${result.ambiguous.review.toString().padEnd(13)} | ${result.ambiguous.reject.toString().padEnd(13)} | ${result.ambiguous.total}
Adversarial / Spoof | ${result.spoof.accept.toString().padEnd(13)} | ${result.spoof.review.toString().padEnd(13)} | ${result.spoof.reject.toString().padEnd(13)} | ${result.spoof.total}
--------------------------------------------------------------------------------

CRITICAL RELEASE GATE INVARIANT:
Known Spoof -> ACCEPT: ${result.spoofAcceptedCount} ${result.passedReleaseGate ? '[PASS - RELEASE APPROVED]' : '[FATAL - RELEASE BLOCKED]'}
================================================================================
`;
  }
}
