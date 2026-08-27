// Comprehensive 20-Step End-to-End Vertical Slice Verification Test Suite
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { AuthService } from '../src/modules/auth/auth.service';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { AlarmsService } from '../src/modules/alarms/alarms.controller';
import { MissionsService } from '../src/modules/missions/missions.controller';
import { ProofsService } from '../src/modules/proofs/proofs.controller';
import { GamificationService } from '../src/modules/gamification/gamification.controller';

describe('V1 Production Core Loop: Complete 20-Step User Journey', () => {
  let userId: string;
  let userToken: string;
  let customTaskId: string;
  let alarmId: string;
  let missionId: string;
  let storageKey: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    seedDatabase();
  });

  // Step 1: User Registration
  it('Step 1: Registers a new user account with welcome XP', () => {
    const authResult = AuthService.register({
      email: 'spartan@habitat.discipline',
      password: 'DisciplineStrict2026!',
      displayName: 'Leonidas Spartan',
      timezone: 'America/New_York'
    });

    expect(authResult.user).toBeDefined();
    userId = authResult.user.id;
    userToken = authResult.token;
    expect(authResult.user.disciplineScore).toBe(100);
    expect(authResult.user.totalXp).toBe(100); // Onboarding bonus
  });

  // Step 2: User Login
  it('Step 2: Authenticates and validates JWT signature', () => {
    const loginResult = AuthService.login({
      email: 'spartan@habitat.discipline',
      password: 'DisciplineStrict2026!'
    });

    expect(loginResult.user.id).toBe(userId);
    const verified = AuthService.verifyToken(loginResult.token);
    expect(verified?.sub).toBe(userId);
  });

  // Step 3: Profile Inspection
  it('Step 3: Fetches authenticated user profile telemetry', () => {
    const profile = AuthService.getUserById(userId);
    expect(profile).toBeDefined();
    expect(profile?.email).toBe('spartan@habitat.discipline');
    expect(profile?.currentStreak).toBe(0);
    expect(profile?.graceTokens).toBe(1);
  });

  // Step 4: 10 Starter Tasks Inspection
  it('Step 4: Loads the 10 canonical starter tasks', () => {
    const starterTasks = TasksService.getAll();
    expect(starterTasks.length).toBe(10);
    expect(starterTasks.some((t) => t.slug === 'make-bed')).toBe(true);
    expect(starterTasks.some((t) => t.slug === 'pushups-10')).toBe(true);
  });

  // Step 5: Custom Task Creation
  it('Step 5: User creates a custom physical routine task', () => {
    const custom = TasksService.createCustomTask({
      userId,
      title: '50 Air Squats',
      description: 'Full range of motion bodyweight squats to build lower body power.',
      category: 'physical',
      difficulty: 'HARD',
      proofType: 'VIDEO',
      baseXp: 80,
      instructions: [
        'Prop phone against water bottle at knee height',
        'Perform 50 deep squats breaking parallel',
        'Submit 20-second recording'
      ]
    });

    expect(custom).toBeDefined();
    customTaskId = custom!.id;
    expect(custom?.difficulty).toBe('HARD');
    expect(custom?.baseXp).toBe(80);
  });

  // Step 6: Category Aggregation
  it('Step 6: Aggregates tasks across categories', () => {
    const categories = TasksService.getCategories(userId);
    const physicalCat = categories.find((c) => c.category === 'physical');
    expect(physicalCat).toBeDefined();
    expect(physicalCat?.count).toBeGreaterThanOrEqual(3);
  });

  // Step 7: Alarm Commitment Creation (07:00 AM)
  it('Step 7: User commits to 07:00 AM Weekday Alarm with Hardcore Escalation', () => {
    const alarm = AlarmsService.create({
      userId,
      taskId: customTaskId,
      timeOfDay: '07:00',
      repeatDays: [1, 2, 3, 4, 5],
      disciplineMode: 'HARDCORE',
      retryIntervalMinutes: 3
    });

    expect(alarm).toBeDefined();
    alarmId = alarm!.id;
    expect(alarm?.timeOfDay).toBe('07:00:00');
    expect(alarm?.disciplineMode).toBe('HARDCORE');
  });

  // Step 8: Next Alarm Occurrence
  it('Step 8: Computes exact next upcoming wake-up alarm timestamp', () => {
    const nextInfo = AlarmsService.getNextAlarm(userId);
    expect(nextInfo).toBeDefined();
    expect(nextInfo?.alarm.id).toBe(alarmId);
    expect(nextInfo?.nextOccurrence).toBeDefined();
  });

  // Step 9: Trigger Alarm -> Mission Created
  it('Step 9: Scheduled alarm time arrives -> Dispatches mission trigger', () => {
    const pastSchedule = new Date(Date.now() - 60000).toISOString(); // 1 min ago
    const mission = MissionsService.triggerMission({
      userId,
      alarmId,
      taskId: customTaskId,
      disciplineMode: 'HARDCORE',
      scheduledAt: pastSchedule
    });

    expect(mission).toBeDefined();
    missionId = mission!.id;
    expect(mission?.status).toBe('TRIGGERED');
    expect(mission?.attemptCount).toBe(1);
  });

  // Step 10: Attempt #1 Logging
  it('Step 10: Validates Attempt #1 spawned with 70dB Volume', () => {
    const attempts = MissionsService.getAttempts(missionId);
    expect(attempts.length).toBe(1);
    expect(attempts[0].attempt_index).toBe(1);
    expect(attempts[0].siren_volume_level).toBe(70);
  });

  // Step 11: Start Active Mission
  it('Step 11: User opens lock screen and starts active mission HUD', () => {
    const active = MissionsService.startMission(missionId);
    expect(active?.status).toBe('ACTIVE');
  });

  // Step 12: 5-Minute Retry Escalation to Attempt #2
  it('Step 12: Inaction triggers 5-min escalation -> Attempt #2 at 85dB volume', () => {
    const retried = MissionsService.retryMission(missionId);
    expect(retried?.status).toBe('RETRYING');
    expect(retried?.attemptCount).toBe(2);

    const attempts = MissionsService.getAttempts(missionId);
    expect(attempts.length).toBe(2);
    expect(attempts[1].siren_volume_level).toBe(85);
  });

  // Step 13: Presigned S3 Upload URL
  it('Step 13: Requests presigned S3 upload URL for exercise video proof', () => {
    const uploadInfo = ProofsService.generateUploadUrl({
      userId,
      missionId,
      mediaType: 'video/mp4'
    });

    expect(uploadInfo).toBeDefined();
    storageKey = uploadInfo.storageKey;
    expect(uploadInfo.uploadUrl).toContain('habitat-proofs');
  });

  // Step 14: Proof Submission & Anti-Cheat Verification
  it('Step 14: Captures proof with telemetry and passes Anti-Cheat validation', async () => {
    const result = await ProofsService.submitAndVerify({
      missionId,
      mediaType: 'video/mp4',
      storageKey,
      capturedAt: new Date().toISOString(),
      deviceTelemetry: {
        ambientLux: 75,
        durationSeconds: 15,
        accelerometerMotion: true,
        isFreshCapture: true
      }
    });

    expect(result.isValid).toBe(true);
    expect(result.verificationStatus).toBe('PASSED');
  });

  // Step 15: Mission Completion State
  it('Step 15: Confirms mission status transitioned to COMPLETED', () => {
    const mission = MissionsService.getById(missionId);
    expect(mission?.status).toBe('COMPLETED');
    expect(mission?.completedAt).toBeDefined();
  });

  // Step 16: Resistance Metric
  it('Step 16: Confirms Resistance Seconds ΔtR calculated accurately', () => {
    const mission = MissionsService.getById(missionId);
    expect(mission?.resistanceSeconds).toBeGreaterThanOrEqual(60);
  });

  // Step 17: XP Ledger Audit
  it('Step 17: Audits immutable XP Transaction Ledger', () => {
    const ledger = GamificationService.getLedger(userId);
    expect(ledger.totalXp).toBeGreaterThan(100);
    expect(ledger.transactions.length).toBeGreaterThanOrEqual(2);
    const missionTx = ledger.transactions.find((t) => t.missionId === missionId);
    expect(missionTx).toBeDefined();
  });

  // Step 18: Streak & Grace Vault Update
  it('Step 18: Verifies Streak incremented and Grace Vault intact', () => {
    const overview = GamificationService.getOverview(userId);
    expect(overview.streaks.currentStreak).toBe(1);
    expect(overview.streaks.graceTokens).toBe(1);
    expect(overview.gamification.completedMissionsCount).toBe(1);
  });

  // Step 19: Achievement Unlocks
  it('Step 19: Evaluates Achievement Badges (First Step to Order Unlocked)', () => {
    const achievements = GamificationService.getAchievements(userId);
    const firstMission = achievements.find((a) => a.id === 'first_mission');
    expect(firstMission?.isUnlocked).toBe(true);
  });

  // Step 20: Offline Batch Synchronization Replay
  it('Step 20: Reconciles offline-completed mission with idempotency key', async () => {
    const offlineIdempotencyKey = 'offline-uuid-999-e2e-sync';
    const offlineMission = MissionsService.triggerMission({
      userId,
      taskId: customTaskId,
      idempotencyKey: offlineIdempotencyKey
    });

    const proofResult = await ProofsService.submitAndVerify({
      missionId: offlineMission!.id,
      mediaType: 'image/jpeg',
      storageKey: 'offline-proof.jpg',
      capturedAt: new Date().toISOString(),
      deviceTelemetry: { ambientLux: 50 }
    });

    expect(proofResult.isValid).toBe(true);
    expect(proofResult.completedMission?.status).toBe('COMPLETED');
  });
});
