// Unit Tests: Resistance (ΔtR), XP Multipliers, Streak & Autonomy
import { describe, it, expect } from 'vitest';
import { MetricsEngine } from '../src/domain/metricsEngine';

describe('MetricsEngine', () => {
  describe('Resistance Calculation (ΔtR)', () => {
    it('accurately calculates resistance in seconds', () => {
      const start = '2026-08-27T07:00:00.000Z';
      const end = '2026-08-27T07:03:15.000Z';
      const resistance = MetricsEngine.calculateResistanceSeconds(start, end);
      expect(resistance).toBe(195); // 3 min 15 sec
    });
  });

  describe('XP Formula and Multipliers', () => {
    it('awards 1.5x Instant Action bonus when completed on first alarm within 2 minutes', () => {
      const result = MetricsEngine.calculateXp({
        baseXp: 50,
        resistanceSeconds: 90, // 1.5 minutes
        attemptsCount: 1,
        disciplineMode: 'DISCIPLINE'
      });

      expect(result.firstAlarmBonus).toBe(true);
      expect(result.speedMultiplier).toBe(1.5);
      expect(result.totalXp).toBe(75); // 50 * 1.5
    });

    it('awards standard 1.0x XP when completed within 5 minutes on first alarm', () => {
      const result = MetricsEngine.calculateXp({
        baseXp: 50,
        resistanceSeconds: 240, // 4 minutes
        attemptsCount: 1,
        disciplineMode: 'DISCIPLINE'
      });

      expect(result.firstAlarmBonus).toBe(true);
      expect(result.speedMultiplier).toBe(1.0);
      expect(result.totalXp).toBe(50);
    });

    it('applies retry penalty and Hardcore 1.3x multiplier', () => {
      const result = MetricsEngine.calculateXp({
        baseXp: 100,
        resistanceSeconds: 660, // 11 minutes
        attemptsCount: 3, // 2 retries
        disciplineMode: 'HARDCORE'
      });

      expect(result.firstAlarmBonus).toBe(false);
      // speedMultiplier: 1.0 - (3 - 1)*0.15 = 0.70
      expect(result.speedMultiplier).toBeCloseTo(0.7);
      expect(result.modeMultiplier).toBe(1.3);
      // 100 * 0.7 * 1.3 = 91
      expect(result.totalXp).toBe(91);
    });
  });

  describe('Streak & Grace Protocol (Progress Over Perfection)', () => {
    it('increments streak on successful mission completion and awards grace token every 14 days', () => {
      // Day 13 -> 14
      const result = MetricsEngine.evaluateStreak(13, 0, true);
      expect(result.newStreak).toBe(14);
      expect(result.newGraceTokens).toBe(1);
      expect(result.usedGraceToken).toBe(false);
      expect(result.streakBroken).toBe(false);
    });

    it('consumes a grace token to protect the streak when a day is missed', () => {
      const result = MetricsEngine.evaluateStreak(20, 1, false);
      expect(result.newStreak).toBe(20);
      expect(result.newGraceTokens).toBe(0);
      expect(result.usedGraceToken).toBe(true);
      expect(result.streakBroken).toBe(false);
    });

    it('breaks streak when no grace tokens are available', () => {
      const result = MetricsEngine.evaluateStreak(20, 0, false);
      expect(result.newStreak).toBe(0);
      expect(result.newGraceTokens).toBe(0);
      expect(result.usedGraceToken).toBe(false);
      expect(result.streakBroken).toBe(true);
    });
  });

  describe('Autonomy Score Calculation', () => {
    it('computes high autonomy score when average resistance is very low', () => {
      // Baseline 15 min, recent avg 1.5 min -> 90% autonomy
      const score = MetricsEngine.calculateAutonomyScore(1.5, 15);
      expect(score).toBe(90);
    });

    it('computes 0% autonomy when resistance equals or exceeds baseline', () => {
      const score = MetricsEngine.calculateAutonomyScore(20, 15);
      expect(score).toBe(0);
    });
  });
});
