// Phase 1 System Health & Acceptance Gate Test Suite
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { HealthService } from '../src/modules/health/health.controller';

describe('Phase 1 Acceptance Gate: Foundation, Database & Health Check', () => {
  beforeAll(() => {
    DatabaseService.resetDbForTesting();
  });

  it('verifies system database connection is online and alive', () => {
    const db = DatabaseService.getDb();
    const result = db.prepare('SELECT 1 as is_alive').get() as any;
    expect(result).toBeDefined();
    expect(result.is_alive).toBe(1);
  });

  it('evaluates health insight and adaptive recommendation modules', () => {
    const recommendation = HealthService.getAdaptiveAlarmRecommendation('test-user');
    expect(recommendation).toBeDefined();
    expect(recommendation.recommendedMode).toBeDefined();
  });
});
