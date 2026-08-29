// Unit & Adversarial Tests: 7-Vector Anti-Spoofing & Replay Attack Corpus
import { describe, it, expect } from 'vitest';
import { AdversarialFixtureGenerator } from './fixtures/adversarial_fixture_generator';
import { VerificationEngine } from '../src/modules/verification/verification.engine';

describe('Adversarial & Anti-Spoofing Matrix', () => {
  const attacks = AdversarialFixtureGenerator.getAllAdversarialAttacks();

  it('Attack 1 (Static Photograph Presentation) -> REJECT', () => {
    const atk = AdversarialFixtureGenerator.getStaticPhotoAttack();
    const result = VerificationEngine.verifyEvidence(atk.evidence, { minRepetitions: 10 });

    expect(result.decision).toBe('REJECT');
    expect(result.decision).not.toBe('ACCEPT');
    expect(result.livenessScore).toBeLessThan(0.40);
  });

  it('Attack 2 (Photo on Smartphone Screen) -> REJECT', () => {
    const atk = AdversarialFixtureGenerator.getPhotoScreenDisplayAttack();
    const result = VerificationEngine.verifyEvidence(atk.evidence, { minRepetitions: 10 });

    expect(result.decision).toBe('REJECT');
    expect(result.decision).not.toBe('ACCEPT');
  });

  it('Attack 3 (Looped Video Replay) -> REJECT', () => {
    const atk = AdversarialFixtureGenerator.getLoopedVideoAttack();
    const result = VerificationEngine.verifyEvidence(atk.evidence, { minRepetitions: 10 });

    expect(result.decision).toBe('REJECT');
    expect(result.decision).not.toBe('ACCEPT');
  });

  it('Attack 4 (Screen Recording Playback) -> REJECT', () => {
    const atk = AdversarialFixtureGenerator.getScreenRecordingAttack();
    const result = VerificationEngine.verifyEvidence(atk.evidence, { minRepetitions: 10 });

    expect(result.decision).toBe('REJECT');
    expect(result.decision).not.toBe('ACCEPT');
  });

  it('Attack 5 (Temporal Manipulation & Jump Splicing) -> REJECT', () => {
    const atk = AdversarialFixtureGenerator.getTemporalManipulationAttack();
    const result = VerificationEngine.verifyEvidence(atk.evidence, { minRepetitions: 10 });

    expect(result.decision).toBe('REJECT');
    expect(result.decision).not.toBe('ACCEPT');
  });

  it('Attack 6 (Multiple People Collision) -> REVIEW / REJECT', () => {
    const atk = AdversarialFixtureGenerator.getMultiplePeopleAttack();
    const result = VerificationEngine.verifyEvidence(atk.evidence, { minRepetitions: 10 });

    expect(['REVIEW', 'REJECT']).toContain(result.decision);
    expect(result.decision).not.toBe('ACCEPT');
  });

  it('Attack 7 (Camera Pointed at Ceiling) -> REJECT', () => {
    const atk = AdversarialFixtureGenerator.getCeilingPointedAttack();
    const result = VerificationEngine.verifyEvidence(atk.evidence, { minRepetitions: 10 });

    expect(result.decision).toBe('REJECT');
    expect(result.decision).not.toBe('ACCEPT');
  });

  it('CRITICAL RELEASE INVARIANT: Zero Known Spoofs Return ACCEPT', () => {
    let spoofAcceptedCount = 0;

    for (const atk of attacks) {
      const result = VerificationEngine.verifyEvidence(atk.evidence, { minRepetitions: 10 });
      if (result.decision === 'ACCEPT') {
        spoofAcceptedCount++;
      }
    }

    expect(spoofAcceptedCount).toBe(0); // The Golden Invariant!
  });
});
