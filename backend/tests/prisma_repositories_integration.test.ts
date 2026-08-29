// Integration & Contract Test Suite for Prisma Repositories (Milestone B3)
import { describe, it, expect, vi } from 'vitest';
import { PrismaClient } from '@prisma/client';
import { PrismaUserRepository } from '../src/repositories/user.repository';
import { PrismaTaskRepository } from '../src/repositories/task.repository';
import { PrismaAlarmRepository } from '../src/repositories/alarm.repository';
import { PrismaMissionRepository } from '../src/repositories/mission.repository';
import { PrismaProofRepository } from '../src/repositories/proof.repository';

describe('Milestone B3: Prisma Repositories Contract & Behavioral Equivalence', () => {
  it('B3.1: PrismaUserRepository implements IUserRepository contract and maps entities', async () => {
    const mockPrisma = {
      user: {
        findUnique: vi.fn().mockResolvedValue({
          id: 'usr_mock_1',
          email: 'test@habitat.app',
          passwordHash: '$2b$10$hashed',
          displayName: 'Test User',
          timezone: 'America/New_York',
          disciplineScore: 100,
          autonomyLevel: 1,
          createdAt: new Date('2026-08-29T10:00:00.000Z'),
          updatedAt: new Date('2026-08-29T10:00:00.000Z')
        }),
        create: vi.fn().mockResolvedValue({
          id: 'usr_mock_new',
          email: 'new@habitat.app',
          passwordHash: 'hash',
          displayName: 'New User',
          timezone: 'UTC',
          disciplineScore: 100,
          autonomyLevel: 1,
          createdAt: new Date(),
          updatedAt: new Date()
        })
      }
    } as unknown as PrismaClient;

    const userRepo = new PrismaUserRepository(mockPrisma);

    const user = await userRepo.findById('usr_mock_1');
    expect(user).not.toBeNull();
    expect(user?.id).toBe('usr_mock_1');
    expect(user?.email).toBe('test@habitat.app');
    expect(user?.createdAt).toBe('2026-08-29T10:00:00.000Z');

    const created = await userRepo.create({
      email: 'new@habitat.app',
      passwordHash: 'hash',
      displayName: 'New User'
    });
    expect(created.id).toBe('usr_mock_new');
    expect(mockPrisma.user.create).toHaveBeenCalled();
  });

  it('B3.2: PrismaTaskRepository implements ITaskRepository contract and maps entities', async () => {
    const mockPrisma = {
      task: {
        findUnique: vi.fn().mockResolvedValue({
          id: 'task_mock_1',
          userId: 'usr_1',
          slug: 'tpl-pushups-10',
          title: '10 Pushups',
          description: 'Standard pushups',
          category: 'PHYSICAL',
          difficulty: 2,
          proofType: 'VIDEO',
          verificationType: 'AI_POSE_REP_COUNTER',
          baseXp: 50,
          estimatedDurationSec: 60,
          iconName: 'fitness_center',
          instructions: 'Perform pushups.',
          validationRules: JSON.stringify({ minReps: 10 }),
          isStarter: true,
          createdAt: new Date('2026-08-29T10:00:00.000Z')
        }),
        findMany: vi.fn().mockResolvedValue([])
      }
    } as unknown as PrismaClient;

    const taskRepo = new PrismaTaskRepository(mockPrisma);

    const task = await taskRepo.findById('task_mock_1');
    expect(task).not.toBeNull();
    expect(task?.slug).toBe('tpl-pushups-10');
    expect(task?.difficulty).toBe('2');
    expect(task?.validationRules).toEqual({ minReps: 10 });
    expect(task?.isStarter).toBe(true);
  });

  it('B3.3: PrismaAlarmRepository implements IAlarmRepository contract and preserves array repeatDays', async () => {
    const mockPrisma = {
      alarm: {
        findMany: vi.fn().mockResolvedValue([
          {
            id: 'alm_mock_1',
            userId: 'usr_1',
            taskId: 'task_1',
            timeOfDay: '06:30:00',
            timezone: 'UTC',
            repeatDays: JSON.stringify([1, 2, 3, 4, 5]),
            disciplineMode: 'DISCIPLINE',
            retryIntervalMinutes: 5,
            isEnabled: true,
            createdAt: new Date(),
            updatedAt: new Date()
          }
        ])
      }
    } as unknown as PrismaClient;

    const alarmRepo = new PrismaAlarmRepository(mockPrisma);

    const alarms = await alarmRepo.findByUserId('usr_1');
    expect(alarms).toHaveLength(1);
    expect(alarms[0].timeOfDay).toBe('06:30:00');
    expect(alarms[0].repeatDays).toEqual([1, 2, 3, 4, 5]);
    expect(alarms[0].isEnabled).toBe(true);
  });

  it('B3.4: PrismaMissionRepository implements IMissionRepository and creates nested initial attempt', async () => {
    const mockPrisma = {
      mission: {
        findUnique: vi.fn().mockResolvedValue({
          id: 'msn_mock_1',
          userId: 'usr_1',
          alarmId: 'alm_1',
          taskId: 'task_1',
          scheduledAt: new Date('2026-08-29T06:30:00.000Z'),
          triggeredAt: new Date('2026-08-29T06:30:01.000Z'),
          completedAt: null,
          status: 'TRIGGERED',
          attemptCount: 1,
          resistanceSeconds: null,
          disciplineMode: 'DISCIPLINE',
          idempotencyKey: 'IDEM_123',
          createdAt: new Date()
        }),
        create: vi.fn().mockResolvedValue({
          id: 'msn_created',
          userId: 'usr_1',
          alarmId: 'alm_1',
          taskId: 'task_1',
          scheduledAt: new Date('2026-08-29T06:30:00.000Z'),
          triggeredAt: new Date(),
          completedAt: null,
          status: 'TRIGGERED',
          attemptCount: 1,
          resistanceSeconds: null,
          disciplineMode: 'DISCIPLINE',
          idempotencyKey: 'IDEM_123',
          createdAt: new Date()
        }),
        update: vi.fn().mockResolvedValue({})
      }
    } as unknown as PrismaClient;

    const missionRepo = new PrismaMissionRepository(mockPrisma);

    const created = await missionRepo.create({
      userId: 'usr_1',
      taskId: 'task_1',
      alarmId: 'alm_1',
      scheduledAt: '2026-08-29T06:30:00.000Z',
      idempotencyKey: 'IDEM_123'
    });

    expect(created.id).toBe('msn_created');
    expect(mockPrisma.mission.create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({
        userId: 'usr_1',
        taskId: 'task_1',
        attempts: {
          create: expect.objectContaining({
            attemptIndex: 1,
            status: 'IGNORED',
            sirenVolumeLevel: 70
          })
        }
      })
    }));
  });

  it('B3.5: PrismaProofRepository implements IProofRepository and handles metadata updates', async () => {
    const mockPrisma = {
      proof: {
        findUnique: vi.fn().mockResolvedValue({
          id: 'prf_mock_1',
          missionId: 'msn_1',
          userId: 'usr_1',
          attemptId: 'att_1',
          uploadId: 'upl_1',
          mediaType: 'VIDEO',
          storageKey: 'proofs/msn_1/proof.mp4',
          objectKey: 'proofs/msn_1/proof.mp4',
          thumbnailKey: null,
          mimeType: 'video/mp4',
          sizeBytes: 1024000,
          sha256: 'abc123sha',
          durationMs: 15000,
          width: 1920,
          height: 1080,
          capturedAt: new Date('2026-08-29T06:31:00.000Z'),
          uploadedAt: new Date('2026-08-29T06:31:05.000Z'),
          verifiedAt: null,
          deviceTelemetry: JSON.stringify({ lux: 50 }),
          verificationStatus: 'PENDING',
          rejectionReason: null,
          createdAt: new Date(),
          updatedAt: new Date()
        }),
        update: vi.fn().mockResolvedValue({})
      }
    } as unknown as PrismaClient;

    const proofRepo = new PrismaProofRepository(mockPrisma);

    const proof = await proofRepo.findById('prf_mock_1');
    expect(proof).not.toBeNull();
    expect(proof?.mediaType).toBe('VIDEO');
    expect(proof?.deviceTelemetry).toEqual({ lux: 50 });

    await proofRepo.updateVerification('prf_mock_1', 'ACCEPTED');
    expect(mockPrisma.proof.update).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'prf_mock_1' },
      data: expect.objectContaining({
        verificationStatus: 'ACCEPTED'
      })
    }));
  });
});
