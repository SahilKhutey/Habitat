// Unit Tests: Mission State Machine & Escalation Curves
import { describe, it, expect } from 'vitest';
import { MissionStateMachine, InvalidStateTransitionError } from '../src/domain/stateMachine';

describe('MissionStateMachine', () => {
  it('allows valid nominal state progression', () => {
    // 1. SCHEDULED -> TRIGGERED
    const s1 = MissionStateMachine.transition(
      { missionId: 'm1', currentStatus: 'SCHEDULED', disciplineMode: 'DISCIPLINE', attemptsCount: 1 },
      'TRIGGERED'
    );
    expect(s1).toBe('TRIGGERED');

    // 2. TRIGGERED -> IN_PROGRESS
    const s2 = MissionStateMachine.transition(
      { missionId: 'm1', currentStatus: 'TRIGGERED', disciplineMode: 'DISCIPLINE', attemptsCount: 1 },
      'IN_PROGRESS'
    );
    expect(s2).toBe('IN_PROGRESS');

    // 3. IN_PROGRESS -> PROOF_SUBMITTED
    const s3 = MissionStateMachine.transition(
      { missionId: 'm1', currentStatus: 'IN_PROGRESS', disciplineMode: 'DISCIPLINE', attemptsCount: 1 },
      'PROOF_SUBMITTED'
    );
    expect(s3).toBe('PROOF_SUBMITTED');

    // 4. PROOF_SUBMITTED -> VERIFYING
    const s4 = MissionStateMachine.transition(
      { missionId: 'm1', currentStatus: 'PROOF_SUBMITTED', disciplineMode: 'DISCIPLINE', attemptsCount: 1 },
      'VERIFYING'
    );
    expect(s4).toBe('VERIFYING');

    // 5. VERIFYING -> COMPLETED (with valid proof)
    const s5 = MissionStateMachine.transition(
      { missionId: 'm1', currentStatus: 'VERIFYING', disciplineMode: 'DISCIPLINE', attemptsCount: 1, hasValidProof: true },
      'COMPLETED'
    );
    expect(s5).toBe('COMPLETED');
  });

  it('rejects invalid state transitions', () => {
    // Cannot skip directly from SCHEDULED to COMPLETED
    expect(() => {
      MissionStateMachine.transition(
        { missionId: 'm1', currentStatus: 'SCHEDULED', disciplineMode: 'DISCIPLINE', attemptsCount: 1 },
        'COMPLETED'
      );
    }).toThrow(InvalidStateTransitionError);

    // Cannot complete without verified proof flag
    expect(() => {
      MissionStateMachine.transition(
        { missionId: 'm1', currentStatus: 'VERIFYING', disciplineMode: 'DISCIPLINE', attemptsCount: 1, hasValidProof: false },
        'COMPLETED'
      );
    }).toThrow(InvalidStateTransitionError);
  });

  it('enforces Hardcore mode failure threshold', () => {
    // In HARDCORE mode, cannot mark as FAILED before 3 attempts
    expect(() => {
      MissionStateMachine.transition(
        { missionId: 'm1', currentStatus: 'TRIGGERED', disciplineMode: 'HARDCORE', attemptsCount: 1 },
        'FAILED'
      );
    }).toThrow(InvalidStateTransitionError);

    // After 3 attempts, failure can be acknowledged
    const status = MissionStateMachine.transition(
      { missionId: 'm1', currentStatus: 'TRIGGERED', disciplineMode: 'HARDCORE', attemptsCount: 3 },
      'FAILED'
    );
    expect(status).toBe('FAILED');
  });

  it('calculates proper siren escalation and haptics per attempt', () => {
    const a1 = MissionStateMachine.calculateEscalation(1, 'DISCIPLINE');
    expect(a1.sirenVolume).toBe(70);
    expect(a1.urgencyLevel).toBe('LOW');
    expect(a1.flashHaptics).toBe(false);

    const a2 = MissionStateMachine.calculateEscalation(2, 'DISCIPLINE');
    expect(a2.sirenVolume).toBe(85);
    expect(a2.urgencyLevel).toBe('MEDIUM');
    expect(a2.flashHaptics).toBe(true);

    const a3 = MissionStateMachine.calculateEscalation(3, 'DISCIPLINE');
    expect(a3.sirenVolume).toBe(100);
    expect(a3.urgencyLevel).toBe('HIGH');

    const a4Hardcore = MissionStateMachine.calculateEscalation(4, 'HARDCORE');
    expect(a4Hardcore.sirenVolume).toBe(100);
    expect(a4Hardcore.urgencyLevel).toBe('MAX');
    expect(a4Hardcore.notifyAccountabilityPartner).toBe(true);
  });
});
