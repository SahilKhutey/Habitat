// Push-Up & Exercise Video Verification Engine (PUSHUP_VIDEO)
import { VerificationCheck, VerificationReason } from '../../domain/verification-reason.enum';
import { PushupStateMachine, PushupState } from '../../domain/pushup-state-machine';

export interface PushupVerificationContext {
  requiredReps?: number;
  motionCycles?: number;
  poseStates?: PushupState[];
  elbowAngles?: number[];
  poseConfidence?: number;
  personDetected?: boolean;
  bodyVisible?: boolean;
  durationSeconds?: number;
}

export class PushupVideoVerifier {
  public static readonly VERSION = 'pushup-v1.0';

  public static verify(ctx: PushupVerificationContext): {
    checks: VerificationCheck[];
    reasons: VerificationReason[];
    validReps: number;
    requiredReps: number;
    confidence: number;
    isAccepted: boolean;
  } {
    const checks: VerificationCheck[] = [];
    const reasons: VerificationReason[] = [];
    const requiredReps = ctx.requiredReps || 10;

    // 1. Person & Body Visibility
    const personPassed = ctx.personDetected ?? true;
    checks.push({
      name: 'PERSON_PRESENT',
      passed: personPassed,
      confidence: personPassed ? 0.95 : 0.10
    });
    if (!personPassed) reasons.push(VerificationReason.PERSON_NOT_DETECTED);

    const bodyPassed = ctx.bodyVisible ?? true;
    checks.push({
      name: 'BODY_VISIBLE',
      passed: bodyPassed,
      confidence: bodyPassed ? 0.93 : 0.15
    });
    if (!bodyPassed) reasons.push(VerificationReason.BODY_NOT_VISIBLE);

    // 2. Video Duration Check
    if (ctx.durationSeconds !== undefined && ctx.durationSeconds < 5) {
      checks.push({
        name: 'VIDEO_DURATION',
        passed: false,
        confidence: 1.0
      });
      reasons.push(VerificationReason.VIDEO_TOO_SHORT);
    }

    // 3. Push-Up State Machine Evaluation
    const sm = new PushupStateMachine();
    if (ctx.poseStates && ctx.poseStates.length > 0) {
      for (const state of ctx.poseStates) {
        sm.transition(state);
      }
    } else if (ctx.elbowAngles && ctx.elbowAngles.length > 0) {
      for (const angle of ctx.elbowAngles) {
        sm.feedAngle(angle);
      }
    }

    const stateMachineReps = sm.getValidReps();
    const detectedReps = ctx.motionCycles !== undefined ? ctx.motionCycles : stateMachineReps;

    const repPassed = detectedReps >= requiredReps;
    checks.push({
      name: 'REPETITION_COUNT',
      passed: repPassed,
      confidence: repPassed ? 0.92 : 0.35,
      details: { detectedReps, requiredReps, shallowReps: sm.getStats().shallowReps }
    });
    if (!repPassed) {
      reasons.push(VerificationReason.INSUFFICIENT_REPETITIONS);
    }

    // 4. Pose Confidence
    const poseConf = ctx.poseConfidence ?? 0.92;
    checks.push({
      name: 'POSE_LANDMARKS',
      passed: poseConf >= 0.75,
      confidence: poseConf
    });
    if (poseConf < 0.75) {
      reasons.push(VerificationReason.INSUFFICIENT_CONFIDENCE);
    }

    const passedChecks = checks.filter((c) => c.passed).length;
    const totalChecks = checks.length;
    const isAccepted = passedChecks === totalChecks && repPassed;
    const confidence = isAccepted ? Math.min(1.0, poseConf) : Math.max(0.3, (detectedReps / requiredReps) * 0.7);

    return {
      checks,
      reasons,
      validReps: detectedReps,
      requiredReps,
      confidence,
      isAccepted
    };
  }
}
