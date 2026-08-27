// Integration Tests for V2 Health & Sleep Resistance Engine
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { HealthService } from '../src/modules/health/health.controller';

describe('V2 Health Engine: Sleep Architecture & Resistance Correlation', () => {
  let defaultUserId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;
  });

  it('records overnight sleep session and computes recovery readiness score', () => {
    const session = HealthService.recordSleepSession({
      userId: defaultUserId,
      startTime: '2026-08-26T22:30:00Z',
      endTime: '2026-08-27T06:15:00Z',
      durationMinutes: 465, // 7h 45m
      deepSleepMinutes: 105,
      remSleepMinutes: 130,
      hrvScore: 68
    });

    expect(session).toBeDefined();
    expect(session.recovery_score).toBeGreaterThanOrEqual(80);
    expect(session.duration_minutes).toBe(465);
  });

  it('queries sleep history and generates correlation insights', () => {
    const insights = HealthService.getHealthInsights(defaultUserId);

    expect(insights).toBeDefined();
    expect(insights.sleepMetrics.sessionsLogged).toBeGreaterThanOrEqual(1);
    expect(insights.sleepMetrics.averageSleepHours).toBeGreaterThan(0);
    expect(insights.wakingResistance.averageResistanceSeconds).toBeDefined();
    expect(insights.correlationInsight.recommendedDisciplineMode).toBeDefined();
  });

  it('computes dynamic adaptive alarm recommendation based on physiological readiness', () => {
    const recommendation = HealthService.getAdaptiveAlarmRecommendation(defaultUserId);

    expect(recommendation).toBeDefined();
    expect(recommendation.recoveryScore).toBeGreaterThanOrEqual(80);
    expect(recommendation.recommendedMode).toBe('HARDCORE');
    expect(recommendation.suggestedRetryInterval).toBe(3);
    expect(recommendation.rationale).toContain('High recovery readiness detected');
  });
});
