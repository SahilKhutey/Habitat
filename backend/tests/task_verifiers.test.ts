// Task Verifiers & Decision Engine Unit Tests
import { describe, it, expect } from 'vitest';
import { OutdoorPhotoVerifier } from '../src/modules/verification/verifiers/photo/outdoor-scene-verifier';
import { BrushingPhotoVerifier } from '../src/modules/verification/verifiers/brushing/brushing-verifier';
import { PushupVideoVerifier } from '../src/modules/verification/verifiers/exercise/pushup-verifier';
import { DecisionEngine } from '../src/modules/verification/engine/decision-engine';
import { VerificationDecision } from '../src/modules/verification/domain/verification-status.enum';

describe('Task Verifiers & Decision Engine Tests', () => {
  it('OutdoorPhotoVerifier: Accepts outdoor daytime photo with person and sky/trees', () => {
    const result = OutdoorPhotoVerifier.verify({
      ambientLux: 80,
      entropyScore: 0.92,
      personCount: 1,
      detectedLabels: ['person', 'sky', 'trees', 'sunlight']
    });

    expect(result.isAccepted).toBe(true);
    expect(result.confidence).toBeGreaterThanOrEqual(0.90);
    expect(result.reasons.length).toBe(0);
  });

  it('OutdoorPhotoVerifier: Rejects indoor photo lacking outdoor scene elements', () => {
    const result = OutdoorPhotoVerifier.verify({
      ambientLux: 40,
      entropyScore: 0.85,
      personCount: 1,
      detectedLabels: ['bedroom', 'bed', 'closet'],
      isOutdoorScene: false
    });

    expect(result.isAccepted).toBe(false);
    expect(result.reasons).toContain('OUTDOOR_SCENE_NOT_CONFIRMED');
  });

  it('BrushingPhotoVerifier: Accepts photo with toothbrush near mouth and face visible', () => {
    const result = BrushingPhotoVerifier.verify({
      personDetected: true,
      faceVisible: true,
      toothbrushDetected: true,
      toothbrushNearMouth: true,
      detectedLabels: ['person', 'face', 'toothbrush']
    });

    expect(result.isAccepted).toBe(true);
    expect(result.confidence).toBeGreaterThanOrEqual(0.90);
  });

  it('BrushingPhotoVerifier: Rejects photo when toothbrush is not near mouth', () => {
    const result = BrushingPhotoVerifier.verify({
      personDetected: true,
      faceVisible: true,
      toothbrushDetected: true,
      toothbrushNearMouth: false
    });

    expect(result.isAccepted).toBe(false);
    expect(result.reasons).toContain('INVALID_ACTION_SEQUENCE');
  });

  it('PushupVideoVerifier: Validates 10 pushups and generates pushup-v1.0 verifier stamp', () => {
    const result = PushupVideoVerifier.verify({
      requiredReps: 10,
      motionCycles: 10,
      poseConfidence: 0.95
    });

    expect(result.isAccepted).toBe(true);
    expect(result.validReps).toBe(10);
    expect(PushupVideoVerifier.VERSION).toBe('pushup-v1.0');
  });

  it('DecisionEngine: Renders ACCEPT for high confidence passing checks', () => {
    const decision = DecisionEngine.decide(
      0.95,
      [{ name: 'PERSON_PRESENT', passed: true, confidence: 0.95 }],
      []
    );

    expect(decision.decision).toBe(VerificationDecision.ACCEPT);
  });

  it('DecisionEngine: Renders REVIEW for ambiguous intermediate confidence', () => {
    const decision = DecisionEngine.decide(
      0.68,
      [{ name: 'OUTDOOR_SCENE', passed: false, confidence: 0.68 }],
      ['OUTDOOR_SCENE_NOT_CONFIRMED' as any]
    );

    expect(decision.decision).toBe(VerificationDecision.REVIEW);
  });
});
