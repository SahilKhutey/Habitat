// Unit & Benchmark Tests: Vision Fixture Corpus (Valid, Invalid & Ambiguous Physical Inputs)
import { describe, it, expect } from 'vitest';
import { VisionFixtureGenerator } from './fixtures/vision_fixture_generator';
import { VerificationEngine } from '../src/modules/verification/verification.engine';

describe('Vision Fixture Benchmarks', () => {
  describe('Valid Genuine Physical Repetitions', () => {
    const validFixtures = VisionFixtureGenerator.getValidFixtures();

    for (const fixture of validFixtures) {
      it(`evaluates ${fixture.name} -> ACCEPT (${fixture.id})`, () => {
        const result = VerificationEngine.verifyEvidence(fixture.evidence, {
          minRepetitions: fixture.minimumExpectedReps ?? 10,
          skipNonceValidation: true
        });

        expect(result.decision).toBe('ACCEPT');
        expect(result.repsVerified).toBeGreaterThanOrEqual(fixture.minimumExpectedReps ?? 10);
        expect(result.truthScore).toBeGreaterThanOrEqual(0.80);
        expect(result.rejectionReason).toBeNull();
      });
    }
  });

  describe('Invalid Physical Repetitions & Form Failures', () => {
    const invalidFixtures = VisionFixtureGenerator.getInvalidFixtures();

    for (const fixture of invalidFixtures) {
      it(`evaluates ${fixture.name} -> REJECT (${fixture.id})`, () => {
        const result = VerificationEngine.verifyEvidence(fixture.evidence, {
          minRepetitions: fixture.minimumExpectedReps ?? 10,
          skipNonceValidation: true
        });

        expect(result.decision).toBe('REJECT');
        expect(result.rejectionReason).toBeDefined();
      });
    }
  });

  describe('Ambiguous / Edge-Case Camera Conditions', () => {
    const ambiguousFixtures = VisionFixtureGenerator.getAmbiguousFixtures();

    for (const fixture of ambiguousFixtures) {
      it(`evaluates ${fixture.name} -> REVIEW (${fixture.id})`, () => {
        const result = VerificationEngine.verifyEvidence(fixture.evidence, {
          minRepetitions: fixture.minimumExpectedReps ?? 10,
          skipNonceValidation: true
        });

        // Uncertainty must route to REVIEW rather than false ACCEPT
        expect(['REVIEW', 'REJECT']).toContain(result.decision);
        expect(result.decision).not.toBe('ACCEPT');
      });
    }
  });
});
