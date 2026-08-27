// Integration Tests for Advanced Engine Tier (AI Verification, Accountability, and Multi-Stage Routines)
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { VerificationEngine } from '../src/modules/verification/verification.engine';
import { AccountabilityService } from '../src/modules/accountability/accountability.controller';
import { RoutinesService } from '../src/modules/routines/routines.controller';

describe('Advanced Engine Tier: AI Verification, Accountability, & Routine Stacks', () => {
  let defaultUserId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;
  });

  describe('Multi-Strategy Verification & AI Rep Counter', () => {
    it('SmartCvVerifier: matches required object labels successfully', () => {
      const result = VerificationEngine.verify({
        taskSlug: 'make-bed',
        proofType: 'PHOTO',
        mediaType: 'image/jpeg',
        capturedAt: new Date().toISOString(),
        deviceTelemetry: {
          ambientLux: 65,
          detectedLabels: ['bed', 'pillow', 'blanket']
        },
        validationRules: {
          minLuminance: 30,
          requiredLabels: ['bed', 'pillow']
        }
      });

      expect(result.isValid).toBe(true);
      expect(result.strategyUsed).toBe('SmartCvVerifier');
      expect(result.confidenceScore).toBeGreaterThanOrEqual(0.9);
    });

    it('PoseRepCounterVerifier: validates repetition cycles for physical routines', () => {
      // 10 Pushups required
      const passResult = VerificationEngine.verify({
        taskSlug: 'pushups-10',
        proofType: 'VIDEO',
        mediaType: 'video/mp4',
        capturedAt: new Date().toISOString(),
        deviceTelemetry: {
          ambientLux: 80,
          durationSeconds: 15,
          motionCycles: 10
        },
        validationRules: {
          minLuminance: 25,
          minRepetitions: 10
        }
      });

      expect(passResult.isValid).toBe(true);
      expect(passResult.strategyUsed).toBe('PoseRepCounterVerifier');
      expect(passResult.extractedMetrics.repsCounted).toBe(10);

      // Insufficient repetitions (only 4 reps detected)
      const failResult = VerificationEngine.verify({
        taskSlug: 'pushups-10',
        proofType: 'VIDEO',
        mediaType: 'video/mp4',
        capturedAt: new Date().toISOString(),
        deviceTelemetry: {
          ambientLux: 80,
          durationSeconds: 15,
          motionCycles: 4
        },
        validationRules: {
          minLuminance: 25,
          minRepetitions: 10
        }
      });

      expect(failResult.isValid).toBe(false);
      expect(failResult.rejectionReason).toContain('Insufficient repetitions detected');
    });
  });

  describe('Accountability Partner Escalation Protocol', () => {
    it('registers an accountability partner and dispatches escalation alert', () => {
      const partner = AccountabilityService.addPartner({
        userId: defaultUserId,
        name: 'Sarah Connor',
        phone: '+15550192834',
        email: 'sarah@resistance.com',
        escalationThreshold: 3
      });

      expect(partner).toBeDefined();
      expect(partner.name).toBe('Sarah Connor');

      // Dispatch alert when attemptCount reaches threshold 3
      const logs = AccountabilityService.dispatchEscalationAlert({
        userId: defaultUserId,
        missionId: 'mission-escalation-xyz',
        taskTitle: '10 Morning Push-Ups',
        attemptCount: 3
      });

      expect(logs.length).toBe(1);
      expect(logs[0].partnerName).toBe('Sarah Connor');
      expect(logs[0].message).toContain('🚨 HABITAT ALERT');
      expect(logs[0].status).toBe('DISPATCHED_MOCK_SMS');
    });
  });

  describe('Multi-Stage Routine Stacks', () => {
    it('creates and queries a 3-step chained routine', () => {
      const tasks = TasksService.getAll();
      const bedTask = tasks.find((t) => t.slug === 'make-bed')!;
      const waterTask = tasks.find((t) => t.slug === 'hydrate-glass')!;
      const sunTask = tasks.find((t) => t.slug === 'morning-sunlight')!;

      const routine = RoutinesService.create({
        userId: defaultUserId,
        title: 'Morning Order Trinity',
        description: 'Bed -> Water -> Sunlight in one uninterrupted stack',
        triggerTime: '06:45',
        repeatDays: [1, 2, 3, 4, 5],
        taskIds: [bedTask.id, waterTask.id, sunTask.id]
      });

      expect(routine).toBeDefined();
      expect(routine?.title).toBe('Morning Order Trinity');
      expect(routine?.totalSteps).toBe(3);
      expect(routine?.tasks[0].title).toBe(bedTask.title);
      expect(routine?.tasks[1].title).toBe(waterTask.title);
      expect(routine?.tasks[2].title).toBe(sunTask.title);
    });
  });
});
