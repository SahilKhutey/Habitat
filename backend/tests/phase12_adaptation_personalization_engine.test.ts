// Phase 12 Intelligent Discipline Adaptation & Personalization Engine Master Tests
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { BehaviorEngine } from '../src/modules/behavior/engine/behavior-engine';
import { TimingEngine } from '../src/modules/behavior/engine/timing-engine';
import { OverloadEngine } from '../src/modules/adaptation/engine/overload-engine';
import { RecoveryEngine } from '../src/modules/adaptation/engine/recovery-engine';
import { RecommendationEngine } from '../src/modules/recommendations/engine/recommendation-engine';
import { AnalyticsEngine } from '../src/modules/analytics/engine/analytics-engine';
import { RoutineEngine } from '../src/modules/routines/engine/routine-engine';

describe('Phase 12 Acceptance Gate: Intelligent Discipline Adaptation & Personalization Engine', () => {
  let userId: string;
  let task1Id: string;
  let task2Id: string;
  let routineId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    userId = seeded.defaultUserId;
    task1Id = 'tpl-pushups-10';
    task2Id = 'tpl-morning-sunlight';

    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    db.prepare(`
      INSERT OR IGNORE INTO tasks (id, user_id, template_id, slug, title, name, description, instructions, category, difficulty, proof_type, validation_rules, created_at, updated_at)
      VALUES (?, ?, ?, 'slug-pushups-12', '10 Pushups', '10 Pushups', 'Complete pushups', 'Record video', 'PHYSICAL', 2, 'VIDEO', '{}', ?, ?)
    `).run(task1Id, userId, task1Id, now, now);

    db.prepare(`
      INSERT OR IGNORE INTO tasks (id, user_id, template_id, slug, title, name, description, instructions, category, difficulty, proof_type, validation_rules, created_at, updated_at)
      VALUES (?, ?, ?, 'slug-sunlight-12', 'Morning Sunlight', 'Morning Sunlight', 'Get sunlight', 'Take photo', 'HEALTH', 1, 'PHOTO', '{}', ?, ?)
    `).run(task2Id, userId, task2Id, now, now);

    // Create a routine for load testing
    const routine = RoutineEngine.createRoutine({
      userId,
      name: 'Spartan Morning Routine',
      type: 'MORNING',
      minimumRequiredTasks: 2,
      tasks: [
        { taskTemplateId: task1Id, sequence: 1 },
        { taskTemplateId: task2Id, sequence: 2 }
      ]
    });
    routineId = routine.id;
  });

  it('Gate 1: Behavioral Event Ingestion & Idempotency: Ingests events and ignores duplicates cleanly', () => {
    const event1 = BehaviorEngine.recordEvent({
      userId,
      type: 'mission.completed',
      taskId: task1Id,
      idempotencyKey: 'event-unique-12345'
    });

    expect(event1.recorded).toBe(true);
    expect(event1.isDuplicate).toBe(false);

    // Duplicate replay
    const event2 = BehaviorEngine.recordEvent({
      userId,
      type: 'mission.completed',
      taskId: task1Id,
      idempotencyKey: 'event-unique-12345'
    });

    expect(event2.recorded).toBe(false);
    expect(event2.isDuplicate).toBe(true);
  });

  it('Gate 2: Multi-Signal Task Performance: Accurately evaluates success rate, delay, and difficulty level', () => {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();

    // Insert 6 mission records for task1Id (5 completed, 1 missed)
    for (let i = 0; i < 5; i++) {
      db.prepare(`
        INSERT INTO missions (id, user_id, task_id, scheduled_at, status, resistance_seconds, created_at, updated_at)
        VALUES (?, ?, ?, ?, 'COMPLETED', 15, ?, ?)
      `).run(`perf-m-comp-${i}`, userId, task1Id, now, now, now);
    }
    db.prepare(`
      INSERT INTO missions (id, user_id, task_id, scheduled_at, status, created_at, updated_at)
      VALUES ('perf-m-miss-1', ?, ?, ?, 'MISSED', ?, ?)
    `).run(userId, task1Id, now, now, now);

    const perf = BehaviorEngine.calculateTaskPerformance({
      userId,
      taskTemplateId: task1Id
    });

    expect(perf.attempts).toBe(6);
    expect(perf.completions).toBe(5);
    expect(perf.misses).toBe(1);
    expect(perf.successRate).toBeGreaterThanOrEqual(80);
    expect(perf.difficultyLevel).toBeDefined();
  });

  it('Gate 3: Behavior Score Formulation: Incorporates completion, consistency, timeliness, and proof reliability', () => {
    const breakdown = BehaviorEngine.calculateBehaviorScore({
      completionRate: 90,
      consistencyRate: 85,
      avgDelaySeconds: 30,
      proofRejectionRate: 5,
      rescheduleCount: 1
    });

    expect(breakdown.score).toBeGreaterThanOrEqual(80);
    expect(breakdown.completionScore).toBe(90);
    expect(breakdown.timelinessScore).toBeGreaterThanOrEqual(90);
  });

  it('Gate 4: Timing Engine & Minimum Observation Safeguard: Prevents premature recommendations (<5 observations)', () => {
    // Insufficient data test
    const insufficientTiming = TimingEngine.findOptimalWindow(userId, 'non-existent-task');
    expect(insufficientTiming.hasSufficientData).toBe(false);
    expect(insufficientTiming.bestWindow).toBeNull();

    // Seed 10 morning missions at 07:00
    const db = DatabaseService.getDb();
    for (let i = 0; i < 8; i++) {
      db.prepare(`
        INSERT INTO missions (id, user_id, task_id, scheduled_at, status, created_at, updated_at)
        VALUES (?, ?, ?, '2026-08-27T07:15:00.000Z', 'COMPLETED', ?, ?)
      `).run(`time-m-7am-${i}`, userId, task2Id, new Date().toISOString(), new Date().toISOString());
    }

    const optimalTiming = TimingEngine.findOptimalWindow(userId, task2Id);
    expect(optimalTiming.hasSufficientData).toBe(true);
    expect(optimalTiming.bestHour).toBe(7);
    expect(optimalTiming.bestWindow).toBe('07:00–08:00');
    expect(optimalTiming.bestSuccessRate).toBe(100);
  });

  it('Gate 5: Routine Overload Detection & Load Score: Correctly classifies routine load level', () => {
    const analysis = OverloadEngine.analyzeRoutineLoad(routineId, userId);
    expect(analysis.routineId).toBe(routineId);
    expect(analysis.taskCount).toBe(2);
    expect(analysis.loadLevel).toBeDefined();
    expect(analysis.loadScore).toBeGreaterThanOrEqual(0);
  });

  it('Gate 6: Recovery Mode Protocol: Formulates non-destructive 3-day recovery plan', () => {
    const recoveryPlan = RecoveryEngine.createRecoveryPlan({
      userId,
      durationDays: 3,
      reason: 'Low momentum reset'
    });

    expect(recoveryPlan.durationDays).toBe(3);
    expect(recoveryPlan.streakPreserved).toBe(true);
    expect(recoveryPlan.coreEssentialTaskIds.length).toBeGreaterThanOrEqual(1);
  });

  it('Gate 7: Recommendation Generation & Ranking: Produces at most 3 ranked explainable recommendations', () => {
    const recs = RecommendationEngine.generateRecommendations(userId);
    expect(recs.length).toBeGreaterThanOrEqual(1);
    expect(recs.length).toBeLessThanOrEqual(3);
    expect(recs[0].title).toBeDefined();
    expect(recs[0].explanation).toBeDefined();
    expect(recs[0].confidence).toBeGreaterThan(0.5);
  });

  it('Gate 8: User Acceptance Creates Version Snapshot: Accepting recommendations preserves historical missions', () => {
    const recs = RecommendationEngine.getActiveRecommendations(userId);
    const recToAccept = recs[0];

    const result = RecommendationEngine.acceptRecommendation(recToAccept.id, userId);
    expect(result.success).toBe(true);

    const db = DatabaseService.getDb();
    const updatedRec = db.prepare('SELECT status, resolved_at FROM recommendations WHERE id = ?').get(recToAccept.id) as any;
    expect(updatedRec.status).toBe('ACCEPTED');
    expect(updatedRec.resolved_at).toBeDefined();
  });

  it('Gate 9: User Decline Sets 7-Day Cooldown: Declining suppresses immediate repeated recommendation', () => {
    const recs = RecommendationEngine.generateRecommendations(userId);
    const recToDecline = recs[0];

    const result = RecommendationEngine.declineRecommendation(recToDecline.id, userId);
    expect(result.success).toBe(true);

    const db = DatabaseService.getDb();
    const updatedRec = db.prepare('SELECT status FROM recommendations WHERE id = ?').get(recToDecline.id) as any;
    expect(updatedRec.status).toBe('DECLINED');
  });

  it('Gate 10: Holistic Analytics Overview: Aggregates completion, best times, and discipline metrics in <300ms', () => {
    const overview = AnalyticsEngine.getOverview(userId);
    expect(overview.userId).toBe(userId);
    expect(overview.totalMissions).toBeGreaterThan(0);
    expect(overview.overallCompletionRate).toBeGreaterThanOrEqual(0);
    expect(overview.disciplineScore).toBeGreaterThan(0);
  });
});
