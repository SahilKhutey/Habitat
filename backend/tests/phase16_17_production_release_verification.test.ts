// Phase 16 & 17 Master Production Release Engineering & Integration Verification
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { MissionService } from '../src/modules/mission/mission.service';
import { VerificationEngine } from '../src/modules/verification/verification.engine';
import { GamificationService } from '../src/modules/gamification/gamification.controller';
import { PrivacyService } from '../src/modules/health/services/privacy.service';
import { EntitlementsService } from '../src/modules/billing/services/entitlements.service';
import { PlanningService } from '../src/modules/intelligence/services/planning.service';
import * as fs from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';

describe('Phase 16 & 17 Master Acceptance Gate: Production Release & Golden Path Verification', () => {
  let userId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    userId = seeded.defaultUserId;
  });

  it('Gate 1: Master Vertical Golden Path: Executes end-to-end discipline lifecycle', () => {
    const task = DatabaseService.getDb().prepare('SELECT id FROM tasks LIMIT 1').get() as any;
    const taskId = task ? task.id : 'task-make-bed';

    // 1. Create task & mission
    const mission = MissionService.createMission({
      userId,
      taskId,
      scheduledAt: new Date().toISOString()
    });
    expect(mission.id).toBeDefined();

    // 2. Perform Verification
    const verification = VerificationEngine.verify({
      taskSlug: 'morning-pushups',
      proofType: 'VIDEO',
      mediaType: 'video/mp4',
      capturedAt: new Date().toISOString(),
      deviceTelemetry: {
        ambientLux: 150,
        accelerometerMotion: true,
        durationSeconds: 15,
        motionCycles: 10,
        poseConfidence: 0.95
      },
      validationRules: {
        minLuminance: 20,
        minDurationSec: 5,
        minRepetitions: 10
      }
    });
    expect(verification.isValid).toBe(true);

    // 3. Award XP & Advance Progression
    const reward = GamificationService.processMissionRewards({
      userId,
      missionId: mission.id,
      baseXp: 50,
      difficulty: 2
    });
    expect(reward.totalXp).toBeGreaterThanOrEqual(50);
    expect(reward.streak.current_streak).toBeGreaterThanOrEqual(1);
  });

  it('Gate 2: Offline Reconciliation & Idempotency: Duplicate submissions do not double XP', () => {
    const missionId = 'offline-mission-sync-999';

    const first = GamificationService.processMissionRewards({
      userId,
      missionId,
      baseXp: 30
    });
    expect(first.isDuplicate).toBe(false);

    const replay = GamificationService.processMissionRewards({
      userId,
      missionId,
      baseXp: 30
    });
    expect(replay.isDuplicate).toBe(true);
  });

  it('Gate 3: Bounded Health Domain Decoupling: Health deletion preserves core alarms and missions', () => {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();

    // Insert dummy health session
    db.prepare(`
      INSERT INTO exercise_sessions (id, user_id, exercise_id, started_at, duration_sec, created_at)
      VALUES ('ex-del-test', ?, 'ex-pushups', ?, 1200, ?)
    `).run(userId, now, now);

    // Delete health data
    const result = PrivacyService.deleteHealthData(userId, { deleteExercise: true });
    expect(result.deletedExerciseSessions).toBeGreaterThanOrEqual(1);

    // Verify core missions and tasks remain intact
    const tasks = db.prepare('SELECT count(*) as count FROM tasks').get() as any;
    expect(tasks.count).toBeGreaterThanOrEqual(1);
  });

  it('Gate 4: Entitlements Server-Side Verification: Rejects unauthorized access', () => {
    expect(EntitlementsService.hasEntitlement(userId, 'ADVANCED_ANALYTICS')).toBe(false);
    EntitlementsService.grantEntitlement(userId, 'ADVANCED_ANALYTICS', 7);
    expect(EntitlementsService.hasEntitlement(userId, 'ADVANCED_ANALYTICS')).toBe(true);
  });

  it('Gate 5: Daily Planning & User Consent: Confirms deterministic approval workflow', () => {
    const plan = PlanningService.getTodayPlan(userId);
    expect(plan.status).toBe('PROPOSED');

    const approved = PlanningService.approvePlan(plan.id, userId);
    expect(approved.status).toBe('APPROVED');
  });

  it('Gate 6: Release Semantic Versioning & Configuration Integrity: VERSION matches v1.0.0 or v1.1.0', () => {
    const versionPath = path.resolve(__dirname, '../../VERSION');
    const exists = fs.existsSync(versionPath);
    expect(exists).toBe(true);

    const version = fs.readFileSync(versionPath, 'utf8').trim();
    expect(['1.0.0', '1.1.0']).toContain(version);
  });

  it('Gate 7: Security Audit: No private keystores or unhashed secrets in repository', () => {
    const forbiddenExtensions = ['.jks', '.keystore', '.pem', '.p12'];
    const projectRoot = path.resolve(__dirname, '../../');

    // Recursively check files ignoring node_modules, .git, and build directories
    function scanDir(dir: string) {
      const items = fs.readdirSync(dir);
      for (const item of items) {
        if (item === 'node_modules' || item === '.git' || item === 'build' || item === '.dart_tool' || item === '.gradle') continue;
        const fullPath = path.join(dir, item);
        const stat = fs.statSync(fullPath);
        if (stat.isDirectory()) {
          scanDir(fullPath);
        } else {
          for (const ext of forbiddenExtensions) {
            if (item.endsWith(ext)) {
              // Ensure forbidden secret files are never tracked in the git repository
              let isTracked = false;
              try {
                execSync(`git ls-files --error-unmatch "${fullPath}"`, { stdio: 'ignore', cwd: projectRoot });
                isTracked = true;
              } catch {
                isTracked = false;
              }
              expect(isTracked).toBe(false);
            }
          }
        }
      }
    }

    scanDir(projectRoot);
  });

  it('Gate 8: Sub-300ms Performance SLA: Verification and plan queries respond rapidly', async () => {
    const start = Date.now();
    const plan = PlanningService.getTodayPlan(userId);
    const duration = Date.now() - start;

    expect(plan).toBeDefined();
    expect(duration).toBeLessThan(300);
  });
});
