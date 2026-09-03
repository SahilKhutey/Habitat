// Production Push-Up Biomechanical & Temporal Evaluator
import { IMissionEvaluator, MissionRequirements, EvaluatorResult } from './evaluator.interface';
import { FramePoseRecord } from '../domain/evidence.types';
import { PushupStateMachine } from '../domain/pushup-state-machine';

export class PushUpEvaluator implements IMissionEvaluator {
  public readonly exerciseType = 'PUSH_UP';

  public static readonly MIN_TEMPORAL_SPREAD_MS = 2500; // Minimum 2.5 seconds of exercise footage
  public static readonly MIN_MOVEMENT_RANGE_DEG = 30; // Minimum 30 deg difference between top and bottom elbow angle
  public static readonly MIN_BODY_ALIGNMENT_DEG = 135; // Plank straightness threshold

  public evaluate(
    trajectory: FramePoseRecord[],
    requirements: MissionRequirements
  ): EvaluatorResult {
    const reasons: string[] = [];
    const targetReps = requirements.targetReps ?? 10;

    if (!trajectory || trajectory.length === 0) {
      return {
        passed: false,
        repsDetected: 0,
        targetReps,
        formQualityScore: 0,
        reasons: ['No pose trajectory data available for exercise evaluation.'],
        stateTransitions: [],
        metrics: {
          shallowRepsCount: 0,
          temporalSpreadMs: 0,
          movementRangeDeg: 0
        }
      };
    }

    // 1. Temporal Monotonicity & Duration Check
    const startMs = trajectory[0].timestampMs;
    const endMs = trajectory[trajectory.length - 1].timestampMs;
    const temporalSpreadMs = Math.max(0, endMs - startMs);

    if (temporalSpreadMs < PushUpEvaluator.MIN_TEMPORAL_SPREAD_MS && trajectory.length >= 10) {
      reasons.push(
        `Insufficient exercise duration: ${temporalSpreadMs}ms (minimum ${PushUpEvaluator.MIN_TEMPORAL_SPREAD_MS}ms required).`
      );
    }

    // 2. Biomechanical Movement Amplitude Range Check
    let minElbowAngle = 180;
    let maxElbowAngle = 0;
    let bodyAlignmentSum = 0;

    for (const frame of trajectory) {
      const meanElbow = (frame.leftElbowAngleDeg + frame.rightElbowAngleDeg) / 2;
      if (meanElbow < minElbowAngle) minElbowAngle = meanElbow;
      if (meanElbow > maxElbowAngle) maxElbowAngle = meanElbow;
      bodyAlignmentSum += frame.bodyAlignmentAngleDeg;
    }

    const movementRangeDeg = Math.max(0, maxElbowAngle - minElbowAngle);
    const meanBodyAlignmentDeg = bodyAlignmentSum / trajectory.length;

    if (movementRangeDeg < PushUpEvaluator.MIN_MOVEMENT_RANGE_DEG) {
      reasons.push(
        `Insufficient elbow flexion range: ${movementRangeDeg.toFixed(1)}° delta (minimum ${PushUpEvaluator.MIN_MOVEMENT_RANGE_DEG}° required).`
      );
    }

    if (meanBodyAlignmentDeg < PushUpEvaluator.MIN_BODY_ALIGNMENT_DEG) {
      reasons.push(
        `Poor body alignment / sagging spine: ${meanBodyAlignmentDeg.toFixed(1)}° (minimum ${PushUpEvaluator.MIN_BODY_ALIGNMENT_DEG}° required).`
      );
    }

    // 3. Push-Up State Machine Evaluation (Full cycles)
    const stateMachine = new PushupStateMachine();
    const stats = stateMachine.feedTrajectory(trajectory);
    const repsDetected = stats.validReps;

    if (repsDetected < targetReps) {
      reasons.push(
        `Insufficient repetitions: completed ${repsDetected}/${targetReps} valid push-ups (detected ${stats.shallowReps} shallow reps).`
      );
    }

    // Form Quality Calculation (0.0 to 1.0)
    let formQualityScore = 1.0;
    if (stats.shallowReps > 0) {
      formQualityScore -= Math.min(0.3, stats.shallowReps * 0.1);
    }
    if (meanBodyAlignmentDeg < 160) {
      formQualityScore -= 0.15;
    }
    formQualityScore = Math.max(0.1, formQualityScore);

    const passed = reasons.length === 0 && repsDetected >= targetReps;

    return {
      passed,
      repsDetected,
      targetReps,
      formQualityScore,
      reasons,
      stateTransitions: stats.stateTransitions,
      metrics: {
        shallowRepsCount: stats.shallowReps,
        meanElbowAngleDeg: (minElbowAngle + maxElbowAngle) / 2,
        meanBodyAlignmentDeg,
        temporalSpreadMs,
        movementRangeDeg
      }
    };
  }
}
