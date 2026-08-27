// Brushing Photo Verification Engine (BRUSHING_PHOTO)
import { VerificationCheck, VerificationReason } from '../../domain/verification-reason.enum';

export interface BrushingVerificationContext {
  personDetected?: boolean;
  faceVisible?: boolean;
  toothbrushDetected?: boolean;
  toothbrushNearMouth?: boolean;
  detectedLabels?: string[];
  ambientLux?: number;
}

export class BrushingPhotoVerifier {
  public static readonly VERSION = 'brushing-v1.0';

  public static verify(ctx: BrushingVerificationContext): {
    checks: VerificationCheck[];
    reasons: VerificationReason[];
    confidence: number;
    isAccepted: boolean;
  } {
    const checks: VerificationCheck[] = [];
    const reasons: VerificationReason[] = [];

    // 1. Person Detection
    const personPassed = ctx.personDetected ?? true;
    checks.push({
      name: 'PERSON_PRESENT',
      passed: personPassed,
      confidence: personPassed ? 0.96 : 0.10
    });
    if (!personPassed) reasons.push(VerificationReason.PERSON_NOT_DETECTED);

    // 2. Face Visibility
    const facePassed = ctx.faceVisible ?? true;
    checks.push({
      name: 'FACE_VISIBLE',
      passed: facePassed,
      confidence: facePassed ? 0.94 : 0.15
    });
    if (!facePassed) reasons.push(VerificationReason.FACE_NOT_VISIBLE);

    // 3. Toothbrush Detection
    const detected = (ctx.detectedLabels || []).map((l) => l.toLowerCase());
    const hasToothbrushLabel = detected.some((d) => d.includes('toothbrush') || d.includes('brush'));
    const toothbrushPassed = ctx.toothbrushDetected ?? (hasToothbrushLabel || detected.length === 0);
    checks.push({
      name: 'TOOTHBRUSH_PRESENT',
      passed: toothbrushPassed,
      confidence: toothbrushPassed ? 0.91 : 0.20
    });
    if (!toothbrushPassed) reasons.push(VerificationReason.OBJECT_NOT_DETECTED);

    // 4. Spatial Proximity: Toothbrush Near Mouth
    const nearMouthPassed = ctx.toothbrushNearMouth ?? true;
    checks.push({
      name: 'TOOTHBRUSH_NEAR_MOUTH',
      passed: nearMouthPassed,
      confidence: nearMouthPassed ? 0.92 : 0.25
    });
    if (!nearMouthPassed) reasons.push(VerificationReason.INVALID_ACTION_SEQUENCE);

    const passedChecks = checks.filter((c) => c.passed).length;
    const totalChecks = checks.length;
    const confidence = passedChecks === totalChecks ? 0.93 : 0.40;
    const isAccepted = passedChecks === totalChecks;

    return {
      checks,
      reasons,
      confidence,
      isAccepted
    };
  }
}
