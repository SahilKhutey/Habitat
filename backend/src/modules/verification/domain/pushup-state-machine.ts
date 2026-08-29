// Push-Up Action Sequence & Repetition State Machine
import { FramePoseRecord } from './evidence.types';

export type PushupState = 'UNKNOWN' | 'TOP' | 'DESCENDING' | 'BOTTOM' | 'ASCENDING';

export interface RepetitionTiming {
  repNumber: number;
  startFrameIndex: number;
  bottomFrameIndex: number;
  endFrameIndex: number;
  durationMs: number;
  isValid: boolean;
  minElbowAngle: number;
  meanBodyAlignment: number;
}

export interface PushupRepetitionStats {
  validReps: number;
  shallowReps: number;
  badFormReps: number;
  currentState: PushupState;
  stateTransitions: PushupState[];
  repTimings: RepetitionTiming[];
  meanRepDurationMs: number;
}

export class PushupStateMachine {
  private state: PushupState = 'UNKNOWN';
  private validReps: number = 0;
  private shallowReps: number = 0;
  private badFormReps: number = 0;
  private reachedBottom: boolean = false;
  private minElbowInCurrentRep: number = 180;
  private currentRepStartTimestamp: number = 0;
  private currentRepStartFrame: number = 0;
  private currentRepBottomFrame: number = 0;
  private bodyAlignmentSum: number = 0;
  private bodyAlignmentSamples: number = 0;
  private stateHistory: PushupState[] = [];
  private repTimings: RepetitionTiming[] = [];

  constructor() {
    this.reset();
  }

  public reset(): void {
    this.state = 'UNKNOWN';
    this.validReps = 0;
    this.shallowReps = 0;
    this.badFormReps = 0;
    this.reachedBottom = false;
    this.minElbowInCurrentRep = 180;
    this.currentRepStartTimestamp = 0;
    this.currentRepStartFrame = 0;
    this.currentRepBottomFrame = 0;
    this.bodyAlignmentSum = 0;
    this.bodyAlignmentSamples = 0;
    this.stateHistory = [];
    this.repTimings = [];
  }

  /**
   * Evaluates landmark elbow angles and body alignment for a single frame
   */
  public feedAngle(
    elbowAngle: number,
    bodyAlignmentAngle: number = 180,
    timestampMs: number = 0,
    frameIndex: number = 0
  ): void {
    this.bodyAlignmentSum += bodyAlignmentAngle;
    this.bodyAlignmentSamples++;

    if (elbowAngle < this.minElbowInCurrentRep) {
      this.minElbowInCurrentRep = elbowAngle;
    }

    // Top Lockout: elbow >= 155 deg
    // Bottom Depth: elbow <= 90 deg
    if (elbowAngle >= 155) {
      this.transition('TOP', timestampMs, frameIndex);
    } else if (elbowAngle <= 90) {
      this.transition('BOTTOM', timestampMs, frameIndex);
    } else if (this.state === 'TOP' || (this.state === 'DESCENDING' && elbowAngle < 155 && elbowAngle > 90)) {
      this.transition('DESCENDING', timestampMs, frameIndex);
    } else if (this.state === 'BOTTOM' || (this.state === 'ASCENDING' && elbowAngle > 90 && elbowAngle < 155)) {
      this.transition('ASCENDING', timestampMs, frameIndex);
    }
  }

  /**
   * Processes a full recorded trajectory sequence of frame pose records
   */
  public feedTrajectory(trajectory: FramePoseRecord[]): PushupRepetitionStats {
    this.reset();
    for (const frame of trajectory) {
      const meanElbow = (frame.leftElbowAngleDeg + frame.rightElbowAngleDeg) / 2;
      this.feedAngle(
        meanElbow,
        frame.bodyAlignmentAngleDeg,
        frame.timestampMs,
        frame.frameIndex
      );
    }
    return this.getStats();
  }

  /**
   * Transitions through push-up phase states
   */
  public transition(nextState: PushupState, timestampMs: number = 0, frameIndex: number = 0): void {
    if (this.state === nextState && this.state !== 'UNKNOWN') {
      return;
    }

    this.stateHistory.push(nextState);

    switch (nextState) {
      case 'DESCENDING':
        if (this.state === 'TOP' || this.state === 'UNKNOWN') {
          this.state = 'DESCENDING';
          this.reachedBottom = false;
          this.minElbowInCurrentRep = 180;
          this.currentRepStartTimestamp = timestampMs;
          this.currentRepStartFrame = frameIndex;
          this.bodyAlignmentSum = 0;
          this.bodyAlignmentSamples = 0;
        }
        break;

      case 'BOTTOM':
        if (this.state === 'DESCENDING' || this.state === 'TOP') {
          this.state = 'BOTTOM';
          this.reachedBottom = true;
          this.currentRepBottomFrame = frameIndex;
        }
        break;

      case 'ASCENDING':
        if (this.state === 'BOTTOM' || this.state === 'DESCENDING') {
          this.state = 'ASCENDING';
        }
        break;

      case 'TOP':
        if (this.state === 'ASCENDING' && this.reachedBottom) {
          const duration = timestampMs > 0 && this.currentRepStartTimestamp > 0
            ? timestampMs - this.currentRepStartTimestamp
            : 1000;
          const avgAlignment = this.bodyAlignmentSamples > 0
            ? this.bodyAlignmentSum / this.bodyAlignmentSamples
            : 180;

          // Biomechanical check: Rep must be >= 500ms to avoid synthetic fast-frame injections
          const isValidTiming = duration >= 500;
          const isGoodForm = avgAlignment >= 135;

          if (isValidTiming && isGoodForm) {
            this.validReps++;
            this.repTimings.push({
              repNumber: this.validReps,
              startFrameIndex: this.currentRepStartFrame,
              bottomFrameIndex: this.currentRepBottomFrame,
              endFrameIndex: frameIndex,
              durationMs: duration,
              isValid: true,
              minElbowAngle: this.minElbowInCurrentRep,
              meanBodyAlignment: Math.round(avgAlignment)
            });
          } else if (!isGoodForm) {
            this.badFormReps++;
          } else {
            this.shallowReps++;
          }

          this.reachedBottom = false;
          this.minElbowInCurrentRep = 180;
        } else if (this.state === 'ASCENDING' && !this.reachedBottom) {
          this.shallowReps++;
        } else if (this.state === 'DESCENDING') {
          this.shallowReps++;
          this.reachedBottom = false;
        }
        this.state = 'TOP';
        break;

      default:
        this.state = nextState;
        break;
    }
  }

  public getStats(): PushupRepetitionStats {
    const totalDuration = this.repTimings.reduce((sum, r) => sum + r.durationMs, 0);
    const meanDuration = this.repTimings.length > 0 ? Math.round(totalDuration / this.repTimings.length) : 0;

    return {
      validReps: this.validReps,
      shallowReps: this.shallowReps,
      badFormReps: this.badFormReps,
      currentState: this.state,
      stateTransitions: [...this.stateHistory],
      repTimings: [...this.repTimings],
      meanRepDurationMs: meanDuration
    };
  }

  public getValidReps(): number {
    return this.validReps;
  }
}
