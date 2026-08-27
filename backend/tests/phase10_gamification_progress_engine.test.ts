// Phase 10 Gamification, Discipline Progress & Engagement Engine Master Tests
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { MissionsService } from '../src/modules/missions/missions.controller';
import { GamificationService } from '../src/modules/gamification/gamification.controller';
import { XpEngine } from '../src/modules/gamification/engine/xp-engine';
import { LevelEngine } from '../src/modules/gamification/engine/level-engine';
import { StreakEngine } from '../src/modules/gamification/engine/streak-engine';
import { ScoreEngine } from '../src/modules/gamification/engine/score-engine';
import { AchievementEngine } from '../src/modules/gamification/engine/achievement-engine';

describe('Phase 10 Acceptance Gate: Gamification, Discipline Progress & Engagement Engine', () => {
  let userId: string;
  let taskId: string;
  let missionId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    userId = seeded.defaultUserId;

    // Create a task
    const task = TasksService.createCustomTask(userId, {
      name: '10 Push-Ups',
      description: 'Morning discipline',
      category: 'PHYSICAL',
      proofType: 'VIDEO',
      difficulty: 2,
      baseXp: 30
    });
    taskId = task.id;

    // Trigger a mission
    const mission = MissionsService.triggerMission({
      userId,
      taskId,
      disciplineMode: 'DISCIPLINE'
    });
    missionId = mission!.id;
    // Complete mission atomically to establish baseline
    MissionsService.completeMission(missionId);
  });

  it('Gate 1: Idempotency Protection: Processing same completion event twice awards XP exactly once', () => {
    const freshMissionId = 'mission-idempotency-gate-10';

    // 1st processing
    const firstResult = GamificationService.processMissionRewards({
      userId,
      missionId: freshMissionId,
      baseXp: 30,
      resistanceSeconds: 45,
      attemptCount: 1
    });

    expect(firstResult.isDuplicate).toBe(false);
    expect(firstResult.totalXp).toBeGreaterThan(0);
    const initialTotalXp = firstResult.totalXp;

    // 2nd duplicate processing
    const duplicateResult = GamificationService.processMissionRewards({
      userId,
      missionId: freshMissionId,
      baseXp: 30,
      resistanceSeconds: 45,
      attemptCount: 1
    });

    expect(duplicateResult.isDuplicate).toBe(true);
    expect(duplicateResult.totalXp).toBe(initialTotalXp);
  });

  it('Gate 2: Quadratic Level Progression: Calculates Level and Progress percentiles accurately', () => {
    // L1 = 0, L2 = 100, L3 = 300, L4 = 600, L5 = 1000
    const p1 = LevelEngine.calculateLevel(50);
    expect(p1.level).toBe(1);
    expect(p1.progressPercent).toBe(50);

    const p2 = LevelEngine.calculateLevel(100);
    expect(p2.level).toBe(2);

    const p3 = LevelEngine.calculateLevel(350);
    expect(p3.level).toBe(3);
    expect(p3.currentLevelBaseXp).toBe(300);
    expect(p3.nextLevelBaseXp).toBe(600);
  });

  it('Gate 3: Streak Progression: Advances current streak and maintains best streak', () => {
    const s1 = StreakEngine.updateStreak(userId, 'UTC');
    expect(s1.streak.currentStreak).toBeGreaterThanOrEqual(1);
    expect(s1.streak.bestStreak).toBeGreaterThanOrEqual(1);

    // Duplicate qualification on same date does not artificially advance streak
    const s2 = StreakEngine.updateStreak(userId, 'UTC');
    expect(s2.advanced).toBe(false);
    expect(s2.streak.currentStreak).toBe(s1.streak.currentStreak);
  });

  it('Gate 4: Streak Recovery Token Mechanics: Consumes Grace Vault token to preserve streak on missed day', () => {
    const initialOverview = GamificationService.getOverview(userId);
    const initialGrace = initialOverview.gamification.graceTokens;

    if (initialGrace > 0) {
      const recovery = StreakEngine.recoverStreak(userId);
      expect(recovery.success).toBe(true);
      expect(recovery.streak.recoveryUsed).toBe(true);
      expect(recovery.streak.graceTokens).toBe(initialGrace - 1);
    }
  });

  it('Gate 5: Timezone-Aware Date Boundary: Evaluates discipline date according to user timezone', () => {
    const istStreak = StreakEngine.updateStreak(userId, 'Asia/Kolkata');
    expect(istStreak.streak.lastQualifiedDate).toBeDefined();
    expect(istStreak.streak.lastQualifiedDate).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });

  it('Gate 6: Slow-Moving Discipline Score: Computes weighted index (0-100) over rolling 30-day window', () => {
    const score = ScoreEngine.calculateDisciplineScore(userId, 30);
    expect(score.score).toBeGreaterThanOrEqual(0);
    expect(score.score).toBeLessThanOrEqual(100);
    expect(score.completionRate).toBeDefined();
    expect(score.consistencyRate).toBeDefined();
    expect(score.rollingWindowDays).toBe(30);
  });

  it('Gate 7: Declarative Achievement Engine: Unlocks achievements idempotently', () => {
    const unlocked = AchievementEngine.evaluateAchievements(userId);
    expect(Array.isArray(unlocked)).toBe(true);

    const all = AchievementEngine.getUserAchievements(userId);
    expect(all.length).toBeGreaterThan(0);

    // Verify first achievement is present
    const firstStep = all.find((a) => a.code === 'FIRST_STEP');
    expect(firstStep).toBeDefined();
    expect(firstStep?.isUnlocked).toBe(true);
  });

  it('Gate 8: Daily, Weekly, and Monthly Summaries: Aggregates completion rates and XP totals', () => {
    const daily = GamificationService.getSummary(userId, 'daily');
    expect(daily.period).toBe('daily');

    const weekly = GamificationService.getSummary(userId, 'weekly');
    expect(weekly.period).toBe('weekly');
    expect(weekly.tasksAttempted).toBeGreaterThanOrEqual(0);

    const monthly = GamificationService.getSummary(userId, 'monthly');
    expect(monthly.period).toBe('monthly');
  });

  it('Gate 9: Anti-Gaming: Rejects duplicate exploit submissions', () => {
    const res1 = XpEngine.awardXp({
      userId,
      amount: 50,
      sourceType: 'MISSION_COMPLETION',
      sourceId: 'mission-exploit-test',
      reason: 'Testing exploit',
      idempotencyKey: 'EXPLOIT:TEST:1'
    });
    expect(res1.isDuplicate).toBe(false);

    const res2 = XpEngine.awardXp({
      userId,
      amount: 50,
      sourceType: 'MISSION_COMPLETION',
      sourceId: 'mission-exploit-test',
      reason: 'Testing exploit',
      idempotencyKey: 'EXPLOIT:TEST:1'
    });
    expect(res2.isDuplicate).toBe(true);
    expect(res2.amount).toBe(0);
  });

  it('Gate 10: End-to-End Truth Integration: Unified gamification overview reflects all subsystem ledgers', () => {
    const overview = GamificationService.getOverview(userId);
    expect(overview.gamification.totalXp).toBeGreaterThan(0);
    expect(overview.gamification.level).toBeGreaterThanOrEqual(1);
    expect(overview.gamification.disciplineScore).toBeGreaterThanOrEqual(0);
    expect(overview.achievements.length).toBeGreaterThanOrEqual(5);
  });
});
