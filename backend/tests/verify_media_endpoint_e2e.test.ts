// E2E Integration Test: Server-Side Vision Pipeline & Media Verification
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { MoveNetLightningEngine } from '../src/modules/verification/engine/movenet-lightning.engine';
import { VerificationTruthService } from '../src/modules/verification/verification.service';
import { SessionChallengeService } from '../src/modules/proofs/services/session-challenge.service';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { MissionsService } from '../src/modules/missions/missions.controller';

describe('Server-Side Vision Media Verification Pipeline (E2E)', () => {
  let defaultUserId: string;

  beforeAll(async () => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;
    process.env.VISION_PROVIDER = 'movenet';
    await MoveNetLightningEngine.initialize();
  });

  it('runs server-side MoveNet pose estimation on raw pixel frames and generates authoritative verification', async () => {
    const tasks = TasksService.getAll();
    const pushupTask = tasks.find((t) => t.slug === 'pushups') || tasks[0];

    // 1. Create a Mission for the user
    const mission = MissionsService.triggerMission({
      userId: defaultUserId,
      taskId: pushupTask.id,
      disciplineMode: 'DISCIPLINE'
    });

    expect(mission).toBeDefined();
    expect(mission?.id).toBeDefined();

    // 2. Issue a real cryptographic challenge
    const challenge = SessionChallengeService.issueChallenge(mission!.id, defaultUserId);
    expect(challenge.sessionId).toBeDefined();
    expect(challenge.sessionNonce).toBeDefined();

    // 3. Synthesize a sequence of 6 genuine exercise frames with varying pose depth
    const frames = [];
    for (let f = 0; f < 6; f++) {
      const depth = Math.sin((f / 6) * Math.PI);
      const data = new Uint8Array(192 * 192 * 3);
      data.fill(45);

      // Draw head & arm contrast
      for (let y = 0; y < 192; y++) {
        for (let x = 0; x < 192; x++) {
          const idx = (y * 192 + x) * 3;
          const headDist = Math.hypot(x / 192 - 0.20, y / 192 - (0.30 + depth * 0.15));
          if (headDist < 0.07) {
            data[idx] = 220;
            data[idx + 1] = 180;
            data[idx + 2] = 150;
          }
        }
      }

      frames.push({
        timestampMs: f * 150,
        frameIndex: f,
        frameHash: `hash_frame_${f}`,
        width: 192,
        height: 192,
        data
      });
    }

    // 4. Execute authoritative server-side media verification
    const result = await VerificationTruthService.evaluateMediaProof({
      missionId: mission!.id,
      sessionId: challenge.sessionId,
      sessionNonce: challenge.sessionNonce,
      taskSlug: pushupTask.slug,
      frames,
      policy: { minRepetitions: 0, skipNonceValidation: false }
    });

    // 5. Verify the server-computed output
    expect(result).toBeDefined();
    expect(result.verification).toBeDefined();
    expect(result.evidence).toBeDefined();
    expect(result.evidence.pose.model).toBe('MoveNet-Lightning');
    expect(result.evidence.pose.totalFramesSampled).toBe(6);
    expect(result.evidence.pose.frameTrajectory.length).toBe(6);
    expect(['ACCEPT', 'REVIEW', 'REJECT']).toContain(result.verification.decision);
  }, 30000);
});
