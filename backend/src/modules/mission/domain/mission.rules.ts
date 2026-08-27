// Domain Mission Status Enums and State Machine Rules
export enum MissionStatus {
  SCHEDULED = 'SCHEDULED',
  ACTIVE = 'ACTIVE',
  IN_PROGRESS = 'IN_PROGRESS',
  VERIFYING = 'VERIFYING',
  RETRY = 'RETRY',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
  EXPIRED = 'EXPIRED',
  ABANDONED = 'ABANDONED'
}

export enum MissionAttemptStatus {
  STARTED = 'STARTED',
  SUBMITTED = 'SUBMITTED',
  ACCEPTED = 'ACCEPTED',
  REJECTED = 'REJECTED'
}

export enum MissionEventType {
  MISSION_CREATED = 'MISSION_CREATED',
  ALARM_TRIGGERED = 'ALARM_TRIGGERED',
  MISSION_STARTED = 'MISSION_STARTED',
  PROOF_SUBMITTED = 'PROOF_SUBMITTED',
  VERIFICATION_FAILED = 'VERIFICATION_FAILED',
  MISSION_RETRY_SCHEDULED = 'MISSION_RETRY_SCHEDULED',
  MISSION_COMPLETED = 'MISSION_COMPLETED',
  MISSION_CANCELLED = 'MISSION_CANCELLED',
  MISSION_EXPIRED = 'MISSION_EXPIRED'
}

export class MissionStateMachine {
  private static readonly allowedTransitions: Record<MissionStatus, MissionStatus[]> = {
    [MissionStatus.SCHEDULED]: [MissionStatus.ACTIVE, MissionStatus.CANCELLED, MissionStatus.EXPIRED],
    [MissionStatus.ACTIVE]: [MissionStatus.IN_PROGRESS, MissionStatus.CANCELLED, MissionStatus.EXPIRED, MissionStatus.ABANDONED],
    [MissionStatus.IN_PROGRESS]: [MissionStatus.VERIFYING, MissionStatus.ACTIVE, MissionStatus.CANCELLED, MissionStatus.EXPIRED, MissionStatus.ABANDONED],
    [MissionStatus.VERIFYING]: [MissionStatus.COMPLETED, MissionStatus.RETRY, MissionStatus.CANCELLED],
    [MissionStatus.RETRY]: [MissionStatus.IN_PROGRESS, MissionStatus.ACTIVE, MissionStatus.CANCELLED, MissionStatus.EXPIRED],
    [MissionStatus.COMPLETED]: [], // Terminal State
    [MissionStatus.CANCELLED]: [], // Terminal State
    [MissionStatus.EXPIRED]: [],   // Terminal State
    [MissionStatus.ABANDONED]: []  // Terminal State
  };

  public static canTransition(from: MissionStatus, to: MissionStatus): boolean {
    const allowed = this.allowedTransitions[from] || [];
    return allowed.includes(to);
  }

  public static assertTransition(from: MissionStatus, to: MissionStatus): void {
    if (!this.canTransition(from, to)) {
      throw new Error(`MISSION_INVALID_STATE: Cannot transition mission from ${from} to ${to}`);
    }
  }
}
