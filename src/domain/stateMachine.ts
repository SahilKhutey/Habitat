// Habitat Mission State Machine Engine
import { MissionStatus, DisciplineMode } from './types';

export class InvalidStateTransitionError extends Error {
  constructor(public from: MissionStatus, public to: MissionStatus, public reason?: string) {
    super(`Invalid mission state transition from '${from}' to '${to}'${reason ? `: ${reason}` : ''}`);
    this.name = 'InvalidStateTransitionError';
  }
}

export interface StateTransitionContext {
  missionId: string;
  currentStatus: MissionStatus;
  disciplineMode: DisciplineMode;
  attemptsCount: number;
  hasValidProof?: boolean;
}

export class MissionStateMachine {
  // Allowed transitions table
  private static readonly VALID_TRANSITIONS: Record<MissionStatus, MissionStatus[]> = {
    SCHEDULED: ['TRIGGERED'],
    TRIGGERED: ['IN_PROGRESS', 'FAILED'],
    IN_PROGRESS: ['PROOF_SUBMITTED', 'TRIGGERED', 'FAILED'], // Can re-trigger on 5-min escalation
    PROOF_SUBMITTED: ['VERIFYING', 'IN_PROGRESS', 'FAILED'],
    VERIFYING: ['COMPLETED', 'IN_PROGRESS', 'FAILED'],
    COMPLETED: [], // Terminal state
    FAILED: []     // Terminal state
  };

  /**
   * Checks if a transition from current status to target status is mathematically valid
   */
  public static canTransition(from: MissionStatus, to: MissionStatus): boolean {
    const allowed = this.VALID_TRANSITIONS[from];
    return allowed ? allowed.includes(to) : false;
  }

  /**
   * Executes and validates state transition with domain guard checks
   */
  public static transition(context: StateTransitionContext, nextStatus: MissionStatus): MissionStatus {
    const { currentStatus, disciplineMode, hasValidProof } = context;

    if (!this.canTransition(currentStatus, nextStatus)) {
      throw new InvalidStateTransitionError(
        currentStatus,
        nextStatus,
        `Transition not permitted by state machine protocol.`
      );
    }

    // Specific domain guards
    if (nextStatus === 'COMPLETED' && !hasValidProof) {
      throw new InvalidStateTransitionError(
        currentStatus,
        nextStatus,
        `Cannot transition to COMPLETED without verified proof.`
      );
    }

    // In HARDCORE mode, missions cannot be simply cancelled or bypassed
    if (nextStatus === 'FAILED' && disciplineMode === 'HARDCORE' && context.attemptsCount < 3) {
      throw new InvalidStateTransitionError(
        currentStatus,
        nextStatus,
        `Hardcore mode prohibits failing a mission before at least 3 escalated attempts.`
      );
    }

    return nextStatus;
  }

  /**
   * Calculates siren volume and escalation parameters for a given attempt index
   */
  public static calculateEscalation(attemptIndex: number, mode: DisciplineMode): {
    sirenVolume: number;
    urgencyLevel: 'LOW' | 'MEDIUM' | 'HIGH' | 'MAX';
    flashHaptics: boolean;
    notifyAccountabilityPartner: boolean;
  } {
    switch (attemptIndex) {
      case 1:
        return {
          sirenVolume: mode === 'GENTLE' ? 50 : 70,
          urgencyLevel: 'LOW',
          flashHaptics: false,
          notifyAccountabilityPartner: false
        };
      case 2: // +5 min
        return {
          sirenVolume: mode === 'GENTLE' ? 70 : 85,
          urgencyLevel: 'MEDIUM',
          flashHaptics: true,
          notifyAccountabilityPartner: false
        };
      case 3: // +10 min
        return {
          sirenVolume: 100,
          urgencyLevel: 'HIGH',
          flashHaptics: true,
          notifyAccountabilityPartner: false
        };
      default: // +15 min and beyond
        return {
          sirenVolume: 100,
          urgencyLevel: 'MAX',
          flashHaptics: true,
          notifyAccountabilityPartner: mode === 'HARDCORE'
        };
    }
  }
}
