// Push-Up Action Sequence & Repetition State Machine

export type PushupState = 'UNKNOWN' | 'TOP' | 'DESCENDING' | 'BOTTOM' | 'ASCENDING';

export interface PushupRepetitionStats {
  validReps: number;
  shallowReps: number;
  currentState: PushupState;
  stateTransitions: PushupState[];
}

export class PushupStateMachine {
  private state: PushupState = 'UNKNOWN';
  private validReps: number = 0;
  private shallowReps: number = 0;
  private reachedBottom: boolean = false;
  private stateHistory: PushupState[] = [];

  constructor() {
    this.reset();
  }

  public reset(): void {
    this.state = 'UNKNOWN';
    this.validReps = 0;
    this.shallowReps = 0;
    this.reachedBottom = false;
    this.stateHistory = [];
  }

  /**
   * Directly transitions through push-up phase states
   */
  public transition(nextState: PushupState): void {
    this.stateHistory.push(nextState);

    switch (nextState) {
      case 'TOP':
        if (this.state === 'ASCENDING' && this.reachedBottom) {
          this.validReps++;
          this.reachedBottom = false;
        } else if (this.state === 'ASCENDING' && !this.reachedBottom) {
          this.shallowReps++;
        } else if (this.state === 'DESCENDING') {
          // Aborted rep (didn't reach bottom)
          this.shallowReps++;
          this.reachedBottom = false;
        }
        this.state = 'TOP';
        break;

      case 'DESCENDING':
        if (this.state === 'TOP' || this.state === 'UNKNOWN') {
          this.state = 'DESCENDING';
          this.reachedBottom = false;
        }
        break;

      case 'BOTTOM':
        if (this.state === 'DESCENDING') {
          this.state = 'BOTTOM';
          this.reachedBottom = true;
        }
        break;

      case 'ASCENDING':
        if (this.state === 'BOTTOM' || this.state === 'DESCENDING') {
          this.state = 'ASCENDING';
        }
        break;

      default:
        this.state = nextState;
        break;
    }
  }

  /**
   * Evaluates landmark elbow angles and body alignment
   * - Top Lockout: elbow > 160 deg
   * - Bottom Depth: elbow < 90 deg
   */
  public feedAngle(elbowAngle: number, bodyAlignmentAngle: number = 180): void {
    // Body alignment check (must remain relatively straight, e.g. > 140 deg)
    if (bodyAlignmentAngle < 130) {
      // Sagging hips or pike
      return;
    }

    if (elbowAngle >= 155) {
      this.transition('TOP');
    } else if (elbowAngle <= 90) {
      this.transition('BOTTOM');
    } else if (this.state === 'TOP' || (this.state === 'DESCENDING' && elbowAngle < 155 && elbowAngle > 90)) {
      this.transition('DESCENDING');
    } else if (this.state === 'BOTTOM' || (this.state === 'ASCENDING' && elbowAngle > 90 && elbowAngle < 155)) {
      this.transition('ASCENDING');
    }
  }

  public getStats(): PushupRepetitionStats {
    return {
      validReps: this.validReps,
      shallowReps: this.shallowReps,
      currentState: this.state,
      stateTransitions: [...this.stateHistory]
    };
  }

  public getValidReps(): number {
    return this.validReps;
  }
}
