// Integration Tests for Phase 07: Proof Engine & Anti-Cheat Verification Pipeline
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { MissionsService } from '../src/modules/missions/missions.controller';
import { ProofsService } from '../src/modules/proofs/proofs.controller';

describe('Phase 07: Proof Engine & Verification Pipeline', () => {
  let defaultUserId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;
  });

  it('generates presigned object storage upload URLs', () => {
    const uploadInfo = ProofsService.generateUploadUrl({
      userId: defaultUserId,
      missionId: 'mission-abc-123',
      mediaType: 'image/jpeg'
    });

    expect(uploadInfo).toBeDefined();
    expect(uploadInfo.storageKey).toContain(`proofs/${defaultUserId}/mission-abc-123/`);
    expect(uploadInfo.uploadUrl).toContain('habitat-proofs');
    expect(uploadInfo.expiresInSeconds).toBe(900);
  });

  it('rejects stale proof captures older than 3 minutes', async () => {
    const task = TasksService.getAll()[0];
    const mission = MissionsService.triggerMission({
      userId: defaultUserId,
      taskId: task.id
    });

    // 10 minutes ago
    const staleTime = new Date(Date.now() - 600000).toISOString();

    const result = await ProofsService.submitAndVerify({
      missionId: mission!.id,
      mediaType: 'image/jpeg',
      storageKey: 'stale-proof.jpg',
      capturedAt: staleTime,
      deviceTelemetry: { ambientLux: 80, isFreshCapture: false }
    });

    expect(result.isValid).toBe(false);
    expect(result.verificationStatus).toBe('REJECTED');
    expect(result.rejectionReason).toContain('stale');

    // Mission must NOT be completed
    const check = MissionsService.getById(mission!.id);
    expect(check?.status).not.toBe('COMPLETED');
  });

  it('rejects dark scenes below task luminance threshold', async () => {
    const task = TasksService.getAll().find((t) => t.slug === 'make-bed')!;
    const mission = MissionsService.triggerMission({
      userId: defaultUserId,
      taskId: task.id
    });

    const result = await ProofsService.submitAndVerify({
      missionId: mission!.id,
      mediaType: 'image/jpeg',
      storageKey: 'dark-proof.jpg',
      capturedAt: new Date().toISOString(),
      deviceTelemetry: { ambientLux: 10 } // Bed requires 30 lux
    });

    expect(result.isValid).toBe(false);
    expect(result.verificationStatus).toBe('REJECTED');
    expect(result.rejectionReason).toContain('too dark');
  });

  it('accepts valid proof, completes mission and inspects proof record', async () => {
    const task = TasksService.getAll().find((t) => t.slug === 'make-bed')!;
    const mission = MissionsService.triggerMission({
      userId: defaultUserId,
      taskId: task.id
    });

    const result = await ProofsService.submitAndVerify({
      missionId: mission!.id,
      mediaType: 'image/jpeg',
      storageKey: 'valid-bed-proof.jpg',
      capturedAt: new Date().toISOString(),
      deviceTelemetry: { ambientLux: 85, accelerometerMotion: true }
    });

    expect(result.isValid).toBe(true);
    expect(result.verificationStatus).toBe('PASSED');
    expect(result.completedMission?.status).toBe('COMPLETED');

    // Inspect proof
    const proof = ProofsService.getById(result.proofId);
    expect(proof).toBeDefined();
    expect(proof?.publicUrl).toContain('valid-bed-proof.jpg');
    expect(proof?.verificationStatus).toBe('PASSED');
  });
});
