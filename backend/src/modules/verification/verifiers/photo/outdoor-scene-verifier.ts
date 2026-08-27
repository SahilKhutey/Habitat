// Outdoor Photo Verification Engine (PHOTO_OUTSIDE)
import { VerificationCheck, VerificationReason } from '../../domain/verification-reason.enum';

export interface OutdoorVerificationContext {
  ambientLux?: number;
  entropyScore?: number;
  detectedLabels?: string[];
  personCount?: number;
  isOutdoorScene?: boolean;
}

export class OutdoorPhotoVerifier {
  public static readonly VERSION = 'outdoor-v1.0';

  public static verify(ctx: OutdoorVerificationContext): {
    checks: VerificationCheck[];
    reasons: VerificationReason[];
    confidence: number;
    isAccepted: boolean;
  } {
    const checks: VerificationCheck[] = [];
    const reasons: VerificationReason[] = [];

    // 1. Image Quality / Illumination Check
    const lux = ctx.ambientLux ?? 50;
    const qualityPassed = lux >= 25 && (ctx.entropyScore ?? 0.85) >= 0.15;
    checks.push({
      name: 'IMAGE_QUALITY',
      passed: qualityPassed,
      confidence: qualityPassed ? 0.95 : 0.20,
      details: { ambientLux: lux, entropy: ctx.entropyScore ?? 0.85 }
    });
    if (!qualityPassed) {
      if (lux < 25) reasons.push(VerificationReason.TOO_DARK);
      if ((ctx.entropyScore ?? 0.85) < 0.15) reasons.push(VerificationReason.LENS_COVERED);
    }

    // 2. Person Present Check
    const personCount = ctx.personCount ?? 1;
    const personPassed = personCount >= 1;
    checks.push({
      name: 'PERSON_PRESENT',
      passed: personPassed,
      confidence: personPassed ? 0.94 : 0.10,
      details: { personCount }
    });
    if (!personPassed) {
      reasons.push(VerificationReason.PERSON_NOT_DETECTED);
    } else if (personCount > 2) {
      reasons.push(VerificationReason.MULTIPLE_PEOPLE);
    }

    // 3. Outdoor Environment Check
    const outdoorKeywords = ['sky', 'sunlight', 'tree', 'vegetation', 'outdoor', 'road', 'park', 'yard', 'balcony'];
    const detected = (ctx.detectedLabels || []).map((l) => l.toLowerCase());
    const hasOutdoorLabel = detected.some((d) => outdoorKeywords.some((kw) => d.includes(kw)));
    const outdoorPassed = ctx.isOutdoorScene === true || hasOutdoorLabel || detected.length === 0;

    checks.push({
      name: 'OUTDOOR_SCENE',
      passed: outdoorPassed,
      confidence: outdoorPassed ? 0.92 : 0.30,
      details: { detectedLabels: ctx.detectedLabels }
    });
    if (!outdoorPassed) {
      reasons.push(VerificationReason.OUTDOOR_SCENE_NOT_CONFIRMED);
    }

    const passedChecks = checks.filter((c) => c.passed).length;
    const totalChecks = checks.length;
    const confidence = passedChecks === totalChecks ? 0.94 : 0.35;
    const isAccepted = passedChecks === totalChecks;

    return {
      checks,
      reasons,
      confidence,
      isAccepted
    };
  }
}
