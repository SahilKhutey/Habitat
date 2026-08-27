// Push-Up State Machine Unit Tests
import { describe, it, expect } from 'vitest';
import { PushupStateMachine } from '../src/modules/verification/domain/pushup-state-machine';

describe('Push-Up State Machine: Action Sequence & Repetition Counter', () => {
  it('Counts 1 valid repetition on full state cycle (TOP -> DESCENDING -> BOTTOM -> ASCENDING -> TOP)', () => {
    const sm = new PushupStateMachine();

    sm.transition('TOP');
    sm.transition('DESCENDING');
    sm.transition('BOTTOM');
    sm.transition('ASCENDING');
    sm.transition('TOP');

    expect(sm.getValidReps()).toBe(1);
    expect(sm.getStats().shallowReps).toBe(0);
  });

  it('Counts 0 valid reps and flags shallow rep on aborted descent (TOP -> DESCENDING -> TOP)', () => {
    const sm = new PushupStateMachine();

    sm.transition('TOP');
    sm.transition('DESCENDING');
    sm.transition('TOP'); // Aborted before reaching bottom

    expect(sm.getValidReps()).toBe(0);
    expect(sm.getStats().shallowReps).toBe(1);
  });

  it('Counts 2 valid repetitions on consecutive full cycles', () => {
    const sm = new PushupStateMachine();

    // Rep 1
    sm.transition('TOP');
    sm.transition('DESCENDING');
    sm.transition('BOTTOM');
    sm.transition('ASCENDING');
    sm.transition('TOP');

    // Rep 2
    sm.transition('DESCENDING');
    sm.transition('BOTTOM');
    sm.transition('ASCENDING');
    sm.transition('TOP');

    expect(sm.getValidReps()).toBe(2);
  });

  it('Evaluates joint angles directly (feedAngle with elbow and body alignment)', () => {
    const sm = new PushupStateMachine();

    // 1. Top Lockout (165 deg)
    sm.feedAngle(165, 175);
    expect(sm.getStats().currentState).toBe('TOP');

    // 2. Descent (120 deg)
    sm.feedAngle(120, 175);
    expect(sm.getStats().currentState).toBe('DESCENDING');

    // 3. Bottom Chest Depth (80 deg)
    sm.feedAngle(80, 170);
    expect(sm.getStats().currentState).toBe('BOTTOM');

    // 4. Ascent (120 deg)
    sm.feedAngle(120, 170);
    expect(sm.getStats().currentState).toBe('ASCENDING');

    // 5. Full Lockout (160 deg)
    sm.feedAngle(160, 175);
    expect(sm.getStats().currentState).toBe('TOP');
    expect(sm.getValidReps()).toBe(1);
  });
});
