// Habitat Metrics, Resistance & Gamification Engine
import { DisciplineMode } from './types';

export interface XpCalculationInput {
  baseXp: number;
  resistanceSeconds: number;
  attemptsCount: number;
  disciplineMode: DisciplineMode;
}

export interface XpCalculationResult {
  totalXp: number;
  speedMultiplier: number;
  modeMultiplier: number;
  firstAlarmBonus: boolean;
  resistanceMinutes: number;
}

export class MetricsEngine {
  /**
   * Calculates resistance in seconds between scheduled/triggered time and completion
   */
  public static calculateResistanceSeconds(startTime: Date | string, completionTime: Date | string): number {
    const start = new Date(startTime).getTime();
    const end = new Date(completionTime).getTime();
    return Math.max(0, Math.round((end - start) / 1000));
  }

  /**
   * Computes XP earned for a completed mission with speed and strictness multipliers
   */
  public static calculateXp(input: XpCalculationInput): XpCalculationResult {
    const { baseXp, resistanceSeconds, attemptsCount, disciplineMode } = input;
    const resistanceMinutes = resistanceSeconds / 60;

    // Speed multiplier logic
    let speedMultiplier = 1.0;
    let firstAlarmBonus = false;

    if (attemptsCount === 1 && resistanceMinutes <= 2) {
      speedMultiplier = 1.5; // +50% Instant Action Bonus
      firstAlarmBonus = true;
    } else if (attemptsCount === 1 && resistanceMinutes <= 5) {
      speedMultiplier = 1.0; // Nominal speed
      firstAlarmBonus = true;
    } else {
      // Penalize procrastination retries
      speedMultiplier = Math.max(0.5, 1.0 - (attemptsCount - 1) * 0.15);
    }

    // Strictness mode multiplier
    let modeMultiplier = 1.0;
    switch (disciplineMode) {
      case 'HARDCORE':
        modeMultiplier = 1.3;
        break;
      case 'DISCIPLINE':
        modeMultiplier = 1.0;
        break;
      case 'GENTLE':
        modeMultiplier = 0.9;
        break;
    }

    const totalXp = Math.round(baseXp * speedMultiplier * modeMultiplier);

    return {
      totalXp,
      speedMultiplier,
      modeMultiplier,
      firstAlarmBonus,
      resistanceMinutes: parseFloat(resistanceMinutes.toFixed(2))
    };
  }

  /**
   * Calculates new Discipline Score (0 - 100 scale) based on recent mission performance
   */
  public static calculateUpdatedDisciplineScore(
    currentScore: number,
    completed: boolean,
    resistanceMinutes: number,
    mode: DisciplineMode
  ): number {
    let delta = 0;

    if (completed) {
      if (resistanceMinutes <= 2) delta = +4;
      else if (resistanceMinutes <= 5) delta = +2;
      else delta = +1;

      if (mode === 'HARDCORE') delta += 1;
    } else {
      // Missed mission penalty
      delta = mode === 'HARDCORE' ? -6 : -4;
    }

    return Math.max(0, Math.min(100, currentScore + delta));
  }

  /**
   * Streak and Grace Protocol Evaluator
   */
  public static evaluateStreak(
    currentStreak: number,
    graceTokens: number,
    missionSuccess: boolean
  ): {
    newStreak: number;
    newGraceTokens: number;
    usedGraceToken: boolean;
    streakBroken: boolean;
  } {
    if (missionSuccess) {
      const newStreak = currentStreak + 1;
      // Award 1 grace token every 14 days of streak (max 3 tokens)
      const earnedGrace = newStreak % 14 === 0 && graceTokens < 3;
      return {
        newStreak,
        newGraceTokens: earnedGrace ? graceTokens + 1 : graceTokens,
        usedGraceToken: false,
        streakBroken: false
      };
    } else {
      // If user failed/missed mission
      if (graceTokens > 0) {
        // Protect streak with Grace Token
        return {
          newStreak: currentStreak,
          newGraceTokens: graceTokens - 1,
          usedGraceToken: true,
          streakBroken: false
        };
      } else {
        // Streak broken
        return {
          newStreak: 0,
          newGraceTokens: 0,
          usedGraceToken: false,
          streakBroken: true
        };
      }
    }
  }

  /**
   * Autonomy Score (0 - 100): Measures internal vs external habit strength
   * Higher score = less reliance on sirens and faster natural execution
   */
  public static calculateAutonomyScore(
    avgRecentResistanceMinutes: number,
    baselineResistanceMinutes: number = 15
  ): number {
    if (baselineResistanceMinutes <= 0) return 100;
    const ratio = avgRecentResistanceMinutes / baselineResistanceMinutes;
    const autonomy = (1 - Math.min(1, Math.max(0, ratio))) * 100;
    return Math.round(autonomy);
  }
}
