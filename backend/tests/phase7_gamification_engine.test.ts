// Phase 7 Gamification, XP, Streaks & Discipline Economy Master Integration Tests
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { GamificationService } from '../src/modules/gamification/gamification.controller';
import { LevelCalculator } from '../src/modules/gamification/domain/level-calculator';
import { BadgeEvaluator } from '../src/modules/gamification/domain/badge-evaluator';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { MissionsService } from '../src/modules/missions/missions.controller';

describe('Phase 7 Acceptance Gate: Gamification, XP Ledger, Streaks, Levels & Badges', () => {
  let userId: string;
  let taskId: string;
  let missionId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    userId = seeded.defaultUserId;

    const task = TasksService.createCustomTask(userId, {
      name: 'Cold Shower Discipline',
      description: '2-minute cold water blast',
      category: 'HEALTH',
      proofType: 'PHOTO',
      difficulty: 2,
      baseXp: 50
    });
    taskId = task.id;

    const mission = MissionsService.triggerMission({
      userId,
      taskId,
      disciplineMode: 'DISCIPLINE'
    });
    missionId = mission!.id;
  });

  it('Gate 1: Computes Level Progression Curve and Progress Percentages accurately', () => {
    // 0 XP -> Level 1
    const l1 = LevelCalculator.calculateLevel(0);
    expect(l1.level).toBe(1);
    expect(l1.xpIntoCurrentLevel).toBe(0);
    expect(l1.progressPercent).toBe(0);

    // 150 XP -> Level 2 (Thresholds: L2 base=100, L3 base=300, 50 XP into L2 of 200 needed = 25%)
    const l2 = LevelCalculator.calculateLevel(150);
    expect(l2.level).toBe(2);
    expect(l2.currentLevelBaseXp).toBe(100);
    expect(l2.nextLevelBaseXp).toBe(300);
    expect(l2.xpIntoCurrentLevel).toBe(50);
    expect(l2.progressPercent).toBe(25);

    // 650 XP -> Level 4 (Thresholds: L4 base=600, L5 base=1000, 50 XP into L4 of 400 needed = 13%)
    const l4 = LevelCalculator.calculateLevel(650);
    expect(l4.level).toBe(4);
    expect(l4.xpIntoCurrentLevel).toBe(50);
  });

  it('Gate 2: Evaluates Daily Discipline Score (0-100) mathematical formula', () => {
    // Perfect performance: 2/2 completed, 2/2 first attempt, 2/2 speed bonus
    const perfectScore = LevelCalculator.calculateDailyDisciplineScore({
      scheduledCount: 2,
      completedCount: 2,
      firstAttemptCount: 2,
      speedBonusCount: 2
    });
    expect(perfectScore).toBe(100);

    // Partial performance: 1/2 completed, 1/1 first attempt, 0 speed bonus -> 0.5*0.5 + 0.3*1.0 + 0 = 0.25 + 0.30 = 0.55 (55)
    const partialScore = LevelCalculator.calculateDailyDisciplineScore({
      scheduledCount: 2,
      completedCount: 1,
      firstAttemptCount: 1,
      speedBonusCount: 0
    });
    expect(partialScore).toBe(55);
  });

  it('Gate 3: Appends discrete, immutable records to XP Ledger with speed bonus provenance', () => {
    const initialLedger = GamificationService.getLedger(userId);
    const initialTotalXp = initialLedger.totalXp;

    // Complete the mission atomically
    MissionsService.completeMission(missionId);

    const updatedLedger = GamificationService.getLedger(userId);
    expect(updatedLedger.totalXp).toBeGreaterThan(initialTotalXp);

    const txBase = updatedLedger.transactions.find((t) => t.reason === 'MISSION_COMPLETED' && t.missionId === missionId);
    expect(txBase).toBeDefined();
    expect(txBase?.amount).toBe(50);
  });

  it('Gate 4: Tracks consecutive streaks and earns Grace Tokens at milestone thresholds', () => {
    const db = DatabaseService.getDb();
    // Simulate streak at 13 days
    db.prepare('UPDATE streaks SET current_streak = 13, grace_tokens = 1 WHERE user_id = ?').run(userId);

    const result = GamificationService.processMissionRewards({
      userId,
      missionId: 'mission-streak-sim',
      baseXp: 20,
      resistanceSeconds: 30,
      attemptCount: 1,
      disciplineMode: 'DISCIPLINE'
    });

    // 14th day reached -> earns 1 bonus Grace Token (now 2)
    expect(result.streak.current_streak).toBe(14);
    expect(result.streak.grace_tokens).toBe(2);
  });

  it('Gate 5: Evaluates canonical achievements and unlocks badges based on criteria', () => {
    const unlocked = BadgeEvaluator.evaluateBadges({
      totalCompletedMissions: 5,
      currentStreak: 14,
      speedBonusCount: 5,
      graceTokens: 3
    });

    const unlockedSlugs = unlocked.map((u) => u.slug);
    expect(unlockedSlugs).toContain('first-step');
    expect(unlockedSlugs).toContain('streak-7');
    expect(unlockedSlugs).toContain('zero-hesitation');
    expect(unlockedSlugs).toContain('grace-vault-guardian');
    expect(unlockedSlugs).not.toContain('streak-30'); // Not at 30 days yet
  });

  it('Gate 6: Gamification Overview API returns unified user discipline stats', () => {
    const overview = GamificationService.getOverview(userId);
    expect(overview.user.id).toBe(userId);
    expect(overview.streaks.currentStreak).toBeGreaterThanOrEqual(1);
    expect(overview.gamification.totalXp).toBeGreaterThan(0);
    expect(overview.gamification.level).toBeGreaterThanOrEqual(1);
  });

  it('Gate 7: Achievements API returns full trophy catalog with unlocked statuses', () => {
    const achievements = GamificationService.getAchievements(userId);
    expect(Array.isArray(achievements)).toBe(true);
    expect(achievements.length).toBeGreaterThanOrEqual(5);

    const firstStep = achievements.find((a) => a.id === 'first_mission');
    expect(firstStep?.isUnlocked).toBe(true);
  });
});
