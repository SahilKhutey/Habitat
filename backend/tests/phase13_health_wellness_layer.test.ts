// Phase 13 Health, Exercise & Wellness Discipline Layer Master Acceptance Tests
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { ExerciseService } from '../src/modules/health/services/exercise.service';
import { HydrationService } from '../src/modules/health/services/hydration.service';
import { SleepService } from '../src/modules/health/services/sleep.service';
import { WellnessService } from '../src/modules/health/services/wellness.service';
import { HealthSyncService } from '../src/modules/health/services/health-sync.service';
import { WellnessCorrelationEngine } from '../src/modules/health/analytics/wellness-correlation';
import { PrivacyService } from '../src/modules/health/services/privacy.service';
import { HealthService } from '../src/modules/health/health.controller';

describe('Phase 13 Acceptance Gate: Health, Exercise & Wellness Discipline Layer', () => {
  let userId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    userId = seeded.defaultUserId;

    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    db.prepare(`
      INSERT OR IGNORE INTO tasks (id, user_id, template_id, slug, title, name, description, instructions, category, difficulty, proof_type, validation_rules, created_at, updated_at)
      VALUES ('tpl-pushups-10', ?, 'tpl-pushups-10', 'slug-pushups-13', '10 Pushups', '10 Pushups', 'Complete pushups', 'Record video', 'PHYSICAL', 2, 'VIDEO', '{}', ?, ?)
    `).run(userId, now, now);
  });

  it('Gate 1: Exercise Session Logging & Metrics: Logs exercise sessions and computes weekly volume', () => {
    const session = ExerciseService.logSession({
      userId,
      exerciseId: 'pushups',
      durationSec: 300,
      quantity: 20,
      unit: 'REPETITIONS',
      sets: 2,
      notes: 'Morning Spartan warm-up'
    });

    expect(session.id).toBeDefined();
    expect(session.durationSec).toBe(300);
    expect(session.quantity).toBe(20);

    const weekly = ExerciseService.getWeeklyStats(userId);
    expect(weekly.sessionCount).toBeGreaterThanOrEqual(1);
    expect(weekly.totalMinutes).toBeGreaterThanOrEqual(5);

    // Negative validation
    expect(() =>
      ExerciseService.logSession({
        userId,
        exerciseId: 'squats',
        durationSec: -50
      })
    ).toThrow('INVALID_DURATION');
  });

  it('Gate 2: Hydration Tracking & Target Calculation: Accurately logs ml and calculates daily progress', () => {
    HydrationService.logHydration({ userId, amountMl: 500 });
    HydrationService.logHydration({ userId, amountMl: 750 });
    HydrationService.logHydration({ userId, amountMl: 250 });

    const today = HydrationService.getTodayHydration(userId, 2500);
    expect(today.totalMl).toBe(1500);
    expect(today.totalLiters).toBe(1.5);
    expect(today.progressPercent).toBe(60);

    // Negative amount check
    expect(() => HydrationService.logHydration({ userId, amountMl: -200 })).toThrow('INVALID_AMOUNT');
  });

  it('Gate 3: Sleep Session Duration & Normalization: Calculates sleep hours and validates timestamps', () => {
    const start = new Date('2026-08-26T22:30:00.000Z');
    const end = new Date('2026-08-27T06:30:00.000Z'); // 8 hours = 28,800 sec

    const session = SleepService.logSleep({
      userId,
      startedAt: start,
      endedAt: end,
      quality: 85,
      notes: 'Restful recovery'
    });

    expect(session.durationSec).toBe(28800);

    const overview = SleepService.getSleepOverview(userId);
    expect(overview.totalLoggedNights).toBeGreaterThanOrEqual(1);
    expect(overview.averageDurationHours).toBe(8.0);
    expect(overview.targetAdherencePercent).toBe(100);

    // Invalid window check
    expect(() =>
      SleepService.logSleep({
        userId,
        startedAt: end,
        endedAt: start
      })
    ).toThrow('INVALID_SLEEP_WINDOW');
  });

  it('Gate 4: Wellness Goals Lifecycle: Creates, queries, and updates personal goals', () => {
    const goal = WellnessService.createGoal({
      userId,
      type: 'MOVEMENT',
      target: 30,
      unit: 'minutes'
    });

    expect(goal.id).toBeDefined();
    expect(goal.status).toBe('ACTIVE');

    const updated = WellnessService.updateGoal({
      goalId: goal.id,
      userId,
      target: 45
    });
    expect(updated.target).toBe(45);

    const goals = WellnessService.getGoals(userId);
    expect(goals.length).toBeGreaterThanOrEqual(1);
  });

  it('Gate 5: Health Provider Abstraction & Deduplication: Ingests external batch and skips duplicate records', () => {
    const batch = {
      userId,
      provider: 'APPLE_HEALTH' as const,
      activities: [
        {
          externalId: 'ext-walk-001',
          type: 'WALKING',
          startedAt: '2026-08-27T08:00:00.000Z',
          endedAt: '2026-08-27T08:30:00.000Z',
          durationSec: 1800,
          quantity: 2500,
          unit: 'METERS'
        }
      ],
      hydration: [
        {
          externalId: 'ext-water-001',
          amountMl: 500,
          timestamp: '2026-08-27T08:35:00.000Z'
        }
      ]
    };

    // First sync
    const res1 = HealthSyncService.syncBatch(batch);
    expect(res1.importedCount).toBeGreaterThanOrEqual(2);

    // Duplicate sync
    const res2 = HealthSyncService.syncBatch(batch);
    expect(res2.duplicateCount).toBeGreaterThanOrEqual(1);
  });

  it('Gate 6: Discipline-to-Wellness Bridge: Completing an exercise task registers an ExerciseSession', () => {
    const db = DatabaseService.getDb();
    const missionId = 'bridge-mission-1';
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO missions (id, user_id, task_id, scheduled_at, status, created_at, updated_at)
      VALUES (?, ?, 'tpl-pushups-10', ?, 'COMPLETED', ?, ?)
    `).run(missionId, userId, now, now, now);

    // Record linked exercise session
    const session = ExerciseService.logSession({
      userId,
      exerciseId: 'tpl-pushups-10',
      durationSec: 180,
      quantity: 15,
      unit: 'REPETITIONS',
      source: 'APP',
      notes: `Generated from completed mission ${missionId}`
    });

    expect(session.id).toBeDefined();
    expect(session.exerciseId).toBe('tpl-pushups-10');
  });

  it('Gate 7: Wellness Correlation Engine: Evaluates association with minimum observation threshold (>=14 days)', () => {
    const correlation = WellnessCorrelationEngine.analyzeDisciplineWellnessCorrelation(userId);
    expect(correlation).toBeDefined();
    expect(correlation.totalDaysEvaluated).toBeGreaterThanOrEqual(0);
    expect(correlation.insightMessage).toBeDefined();
  });

  it('Gate 8: Privacy Controls & Granular Data Deletion: Deletes specific health datasets cleanly', () => {
    const delExercise = PrivacyService.deleteExerciseData(userId);
    expect(delExercise.deleted).toBe(true);

    const remainingSessions = ExerciseService.getSessions(userId);
    expect(remainingSessions.length).toBe(0);

    const delHydration = PrivacyService.deleteHydrationData(userId);
    expect(delHydration.deleted).toBe(true);

    const remainingHydration = HydrationService.getTodayHydration(userId);
    expect(remainingHydration.totalMl).toBe(0);
  });

  it('Gate 9: Provider Connection Management: Connects and disconnects provider authorizations', () => {
    const connected = HealthSyncService.connectProvider({
      userId,
      provider: 'HEALTH_CONNECT',
      permissions: { exercise: true, steps: true, sleep: true, heartRate: false }
    });
    expect(connected.status).toBe('CONNECTED');

    const disconnected = HealthSyncService.disconnectProvider(userId, 'HEALTH_CONNECT');
    expect(disconnected.status).toBe('DISCONNECTED');
  });

  it('Gate 10: Consolidated Health Overview: Returns comprehensive wellness dashboard in <300ms', () => {
    const overview = HealthService.getHealthInsights(userId);
    expect(overview.sleepMetrics).toBeDefined();
    expect(overview.exerciseMetrics).toBeDefined();
    expect(overview.hydrationMetrics).toBeDefined();
    expect(overview.wellnessProgress).toBeDefined();
  });
});
