// Integration Tests: End-to-End API & Mission Flow
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { TaskRepository } from '../src/db/repositories/taskRepository';
import { AlarmRepository } from '../src/db/repositories/alarmRepository';
import { MissionRepository } from '../src/db/repositories/missionRepository';
import { MissionService } from '../src/services/missionService';
import { UserRepository } from '../src/db/repositories/userRepository';

describe('Habitat End-to-End Mission & API Engine', () => {
  let defaultUserId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;
  });

  it('loads 10 starter tasks correctly into repository', () => {
    const tasks = TaskRepository.getAll();
    expect(tasks.length).toBe(10);
    const bedTask = TaskRepository.getBySlug('make-bed');
    expect(bedTask).toBeDefined();
    expect(bedTask?.category).toBe('environment');
    expect(bedTask?.proofType).toBe('PHOTO');
  });

  it('creates a scheduled alarm commitment', () => {
    const bedTask = TaskRepository.getBySlug('make-bed')!;
    const alarm = AlarmRepository.create({
      userId: defaultUserId,
      taskId: bedTask.id,
      timeOfDay: '07:00:00',
      repeatDays: [1, 2, 3, 4, 5],
      disciplineMode: 'DISCIPLINE',
      retryIntervalMinutes: 5,
      escalationEnabled: true,
      soundPack: 'TACTICAL_SIREN',
      isActive: true
    });

    expect(alarm.id).toBeDefined();
    expect(alarm.timeOfDay).toBe('07:00:00');
    expect(alarm.disciplineMode).toBe('DISCIPLINE');

    const retrieved = AlarmRepository.getById(alarm.id);
    expect(retrieved?.id).toBe(alarm.id);
  });

  it('executes full mission lifecycle: Trigger -> Start -> Proof Verification -> Completion & XP Award', async () => {
    const pushupTask = TaskRepository.getBySlug('pushups-10')!;
    const userBefore = UserRepository.getById(defaultUserId)!;
    const initialStreak = userBefore.currentStreak;
    const initialXp = userBefore.totalXp;

    // 1. Trigger Mission
    const scheduledTime = new Date().toISOString();
    const mission = await MissionService.triggerMission({
      userId: defaultUserId,
      taskId: pushupTask.id,
      disciplineMode: 'HARDCORE',
      scheduledFor: scheduledTime
    });

    expect(mission.status).toBe('TRIGGERED');
    expect(mission.attemptsCount).toBe(1);

    // 2. User acknowledges wake-up and starts mission
    const started = MissionService.startMission(mission.id);
    expect(started.status).toBe('IN_PROGRESS');

    // 3. User submits proof (video with motion)
    const verification = await MissionService.submitAndVerifyProof(mission.id, {
      missionId: mission.id,
      mediaType: 'video/mp4',
      storageUrl: '/uploads/proof-pushups.mp4',
      capturedAt: new Date().toISOString(),
      deviceMetadata: {
        ambientLux: 80,
        accelerometerMotion: true,
        appVersion: '1.0.0-test'
      }
    });

    expect(verification.isValid).toBe(true);
    expect(verification.mission.status).toBe('COMPLETED');
    expect(verification.mission.resistanceSeconds).toBeDefined();
    expect(verification.mission.xpAwarded).toBeGreaterThan(0);

    // 4. Verify User stats updated
    const userAfter = UserRepository.getById(defaultUserId)!;
    expect(userAfter.currentStreak).toBe(initialStreak + 1);
    expect(userAfter.totalXp).toBe(initialXp + verification.mission.xpAwarded);
  });

  it('rejects spoofed / pitch-dark proof submissions', async () => {
    const bedTask = TaskRepository.getBySlug('make-bed')!;
    const mission = await MissionService.triggerMission({
      userId: defaultUserId,
      taskId: bedTask.id,
      disciplineMode: 'DISCIPLINE'
    });

    // Submit pitch dark photo (ambientLux: 5 lux when task requires min 30)
    const failedVerification = await MissionService.submitAndVerifyProof(mission.id, {
      missionId: mission.id,
      mediaType: 'image/jpeg',
      storageUrl: '/uploads/dark-photo.jpg',
      capturedAt: new Date().toISOString(),
      deviceMetadata: {
        ambientLux: 5, // Below 30 lux threshold
        accelerometerMotion: false
      }
    });

    expect(failedVerification.isValid).toBe(false);
    expect(failedVerification.rejectionReason).toContain('Scene is too dark');
    expect(failedVerification.mission.status).not.toBe('COMPLETED');
  });
});
