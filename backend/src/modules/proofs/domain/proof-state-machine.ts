// Proof State Machine Validator & Lifecycle Transition Engine
import { ProofStatus } from './proof.types';

export class ProofStateMachine {
  private static readonly allowedTransitions: Record<ProofStatus, ProofStatus[]> = {
    CAPTURING: ['CAPTURED', 'DELETED', 'EXPIRED'],
    CAPTURED: ['UPLOAD_PENDING', 'UPLOADING', 'DELETED', 'EXPIRED'],
    UPLOAD_PENDING: ['UPLOADING', 'DELETED', 'EXPIRED'],
    UPLOADING: ['UPLOADED', 'UPLOAD_PENDING', 'DELETED', 'EXPIRED'],
    UPLOADED: ['VALIDATING', 'DELETED', 'EXPIRED'],
    VALIDATING: ['ACCEPTED', 'REJECTED', 'DELETED'],
    ACCEPTED: ['DELETED'],
    REJECTED: ['CAPTURING', 'DELETED', 'EXPIRED'],
    EXPIRED: ['DELETED'],
    DELETED: [] // Terminal state
  };

  /**
   * Validates whether a state transition from `from` to `to` is legally permitted.
   */
  public static canTransition(from: ProofStatus, to: ProofStatus): boolean {
    const allowed = this.allowedTransitions[from] || [];
    return allowed.includes(to);
  }

  /**
   * Asserts transition validity and throws domain error if illegal.
   */
  public static assertTransition(from: ProofStatus, to: ProofStatus): void {
    if (!this.canTransition(from, to)) {
      throw new Error(`Illegal Proof State Transition: Cannot move from ${from} to ${to}`);
    }
  }
}
