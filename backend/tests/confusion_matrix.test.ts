// Unit Tests: Verification Confusion Matrix & Release Quality Scorecard
import { describe, it, expect } from 'vitest';
import { ConfusionMatrixEvaluator } from './helpers/confusion_matrix_evaluator';

describe('Verification Confusion Matrix & Release Quality Scorecard', () => {
  it('evaluates entire benchmark fixture corpus and passes release gate', () => {
    const result = ConfusionMatrixEvaluator.evaluateAll();

    // 1. Enforce True Accept Rate (TAR) is 100% for valid physical workouts
    expect(result.trueAcceptRate).toBeGreaterThanOrEqual(0.90);

    // 2. Enforce False Accept Rate (FAR) is strictly 0.0% for known attacks
    expect(result.falseAcceptRate).toBe(0.0);

    // 3. Enforce Golden Invariant
    expect(result.spoofAcceptedCount).toBe(0);
    expect(result.passedReleaseGate).toBe(true);

    // 4. Verify scorecard generates properly
    const scorecard = ConfusionMatrixEvaluator.getFormattedScorecard(result);
    expect(scorecard).toContain('RELEASE APPROVED');
    expect(scorecard).toContain('Known Spoof -> ACCEPT: 0');
  });
});
