// Integration Tests for V4 Autonomous AI Coach & Behavioral Adaptation
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { CoachService } from '../src/modules/coach/coach.controller';

describe('V4 Autonomous AI Coach: Briefings & Behavioral Adaptation', () => {
  let defaultUserId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;
  });

  it('generates a personalized daily briefing based on recovery & streak telemetry', () => {
    const briefing = CoachService.generateDailyBriefing(defaultUserId);

    expect(briefing).toBeDefined();
    expect(briefing.insightType).toBe('BRIEFING');
    expect(briefing.headline).toBeDefined();
    expect(briefing.content).toContain('Alex Mercer');
    expect(briefing.actionableRecommendation).toBeDefined();
    expect(briefing.currentStreak).toBeGreaterThan(0);
  });

  it('retrieves saved coach insights and behavioral recommendations', () => {
    const insights = CoachService.getInsights(defaultUserId);

    expect(insights.length).toBeGreaterThanOrEqual(1);
    expect(insights[0].headline).toBeDefined();
    expect(insights[0].actionableRecommendation).toBeDefined();
  });

  it('evaluates and executes autonomous schedule adaptation', () => {
    const result = CoachService.adaptSchedule(defaultUserId);

    expect(result).toBeDefined();
    expect(result.success).toBe(true);
    expect(result.message).toBeDefined();
    expect(result.adaptedAt).toBeDefined();
  });
});
