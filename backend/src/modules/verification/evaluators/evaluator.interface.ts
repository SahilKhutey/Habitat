// Mission-Specific Evaluator Interface & Common Types
import { FramePoseRecord } from '../domain/evidence.types';

export interface MissionRequirements {
  taskSlug?: string;
  exerciseType?: string;
  targetReps?: number;
  minConfidence?: number;
  minDurationSeconds?: number;
  maxDurationSeconds?: number;
}

export interface EvaluatorResult {
  passed: boolean;
  repsDetected: number;
  targetReps: number;
  formQualityScore: number;
  reasons: string[];
  stateTransitions: string[];
  metrics: {
    shallowRepsCount: number;
    meanElbowAngleDeg?: number;
    meanBodyAlignmentDeg?: number;
    temporalSpreadMs?: number;
    movementRangeDeg?: number;
  };
}

export interface IMissionEvaluator {
  readonly exerciseType: string;
  evaluate(
    trajectory: FramePoseRecord[],
    requirements: MissionRequirements
  ): EvaluatorResult;
}
