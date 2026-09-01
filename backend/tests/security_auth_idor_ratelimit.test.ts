// Comprehensive Security Suite: Authentication Guard, IDOR Protection & Rate Limiting (Track D)
import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { AuthSecurity } from '../src/modules/auth/auth.security';
import { MissionsService } from '../src/modules/missions/missions.controller';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { ProofsService } from '../src/modules/proofs/proofs.controller';
import { StorageFactory } from '../src/modules/storage/storage.factory';
import { SecurityService } from '../src/modules/security/security.service';
import { authGuard, AuthenticatedRequest } from '../src/common/guards/auth.guard';
import { SessionChallengeService } from '../src/modules/proofs/services/session-challenge.service';
import { Response } from 'express';

import { MoveNetLightningEngine } from '../src/modules/verification/engine/movenet-lightning.engine';

describe('Track D: Authentication, Ownership IDOR & Rate Limiting', () => {
  let userAId: string;
  let userBId: string;
  let tokenA: string;
  let tokenB: string;
  let task: { id: string; slug: string };
  const originalVisionProvider = process.env.VISION_PROVIDER;

  beforeAll(async () => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    userAId = seeded.defaultUserId;

    // Create User B in DB
    const db = DatabaseService.getDb();
    userBId = 'user-attacker-uuid-456';
    const now = new Date().toISOString();
    db.prepare(`
      INSERT INTO users (id, email, password_hash, display_name, created_at, updated_at)
      VALUES (?, 'attacker@test.com', 'hash', 'Attacker', ?, ?)
    `).run(userBId, now, now);

    tokenA = AuthSecurity.generateAccessToken(userAId, 'userA@test.com');
    tokenB = AuthSecurity.generateAccessToken(userBId, 'attacker@test.com');

    const tasks = TasksService.getAll();
    task = tasks.find((t) => t.slug === 'pushups') || tasks[0];

    process.env.VISION_PROVIDER = 'movenet';
    await MoveNetLightningEngine.initialize();
  });

  afterAll(() => {
    process.env.VISION_PROVIDER = originalVisionProvider;
  });

  beforeEach(() => {
    SecurityService.clearAllForTesting();
    SessionChallengeService.resetForTesting();
  });

  describe('1. AuthGuard Middleware Enforcement', () => {
    function mockResponse() {
      const res: any = {};
      res.statusCode = 200;
      res.status = (code: number) => {
        res.statusCode = code;
        return res;
      };
      res.json = (body: any) => {
        res.body = body;
        return res;
      };
      return res as Response & { statusCode: number; body: any };
    }

    it('rejects unauthenticated request missing Authorization header (401)', () => {
      const req: any = { headers: {} };
      const res = mockResponse();
      let nextCalled = false;

      authGuard(req, res, () => { nextCalled = true; });

      expect(nextCalled).toBe(false);
      expect(res.statusCode).toBe(401);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
    });

    it('rejects request with invalid or tampered JWT token (401)', () => {
      const req: any = { headers: { authorization: 'Bearer invalid.tampered.token' } };
      const res = mockResponse();
      let nextCalled = false;

      authGuard(req, res, () => { nextCalled = true; });

      expect(nextCalled).toBe(false);
      expect(res.statusCode).toBe(401);
      expect(res.body.error.code).toBe('INVALID_TOKEN_TYPE');
    });

    it('allows valid bearer token and sets req.user context', () => {
      const req: any = { headers: { authorization: `Bearer ${tokenA}` } };
      const res = mockResponse();
      let nextCalled = false;

      authGuard(req, res, () => { nextCalled = true; });

      expect(nextCalled).toBe(true);
      expect(req.user).toBeDefined();
      expect(req.user.userId).toBe(userAId);
    });
  });

  describe('2. Proof & Mission IDOR Ownership Protection', () => {
    it('prevents User B from creating an upload session for User A mission', () => {
      const missionA = MissionsService.triggerMission({
        userId: userAId,
        taskId: task.id,
        disciplineMode: 'DISCIPLINE'
      });

      expect(() => {
        ProofsService.createUploadSession({
          userId: userBId, // Attacker attempts to attach proof to User A's mission
          missionId: missionA!.id,
          type: 'PHOTO',
          mimeType: 'image/jpeg',
          sizeBytes: 1000
        });
      }).toThrowError(/FORBIDDEN_IDOR_VIOLATION/);
    });

    it('prevents User B from completing or downloading User A proof', async () => {
      const missionA = MissionsService.triggerMission({
        userId: userAId,
        taskId: task.id,
        disciplineMode: 'DISCIPLINE'
      });

      const uploadA = ProofsService.createUploadSession({
        userId: userAId,
        missionId: missionA!.id,
        type: 'PHOTO',
        mimeType: 'image/jpeg',
        sizeBytes: 1000
      });

      const storage = StorageFactory.getProvider();
      await storage.saveBuffer!(uploadA.objectKey, Buffer.alloc(100), 'image/jpeg');

      // User B attempts to complete User A's upload
      expect(() => {
        ProofsService.completeUpload(uploadA.proofId, userBId);
      }).toThrowError(/UNAUTHORIZED|FORBIDDEN_IDOR_VIOLATION/);

      // User B attempts to access User A's proof
      expect(() => {
        ProofsService.getById(uploadA.proofId, userBId);
      }).toThrowError(/FORBIDDEN_IDOR_VIOLATION/);

      // User B attempts to get download URL for User A's proof
      await expect(
        ProofsService.getDownloadUrl(uploadA.proofId, userBId)
      ).rejects.toThrowError(/FORBIDDEN_IDOR_VIOLATION/);

      // User B attempts to delete User A's proof
      expect(() => {
        ProofsService.deleteProof(uploadA.proofId, userBId);
      }).toThrowError(/FORBIDDEN_IDOR_VIOLATION/);
    });

    it('prevents User B from executing verifyWithRealVision on User A proof', async () => {
      const missionA = MissionsService.triggerMission({
        userId: userAId,
        taskId: task.id,
        disciplineMode: 'DISCIPLINE'
      });

      const uploadA = ProofsService.createUploadSession({
        userId: userAId,
        missionId: missionA!.id,
        type: 'PHOTO',
        mimeType: 'image/jpeg',
        sizeBytes: 192 * 192 * 3
      });

      const storage = StorageFactory.getProvider();
      await storage.saveBuffer!(uploadA.objectKey, Buffer.alloc(192 * 192 * 3, 50), 'image/jpeg');

      // User B attempts to run verifyWithRealVision
      await expect(
        ProofsService.verifyWithRealVision(uploadA.proofId, { minRepetitions: 0 }, userBId)
      ).rejects.toThrowError(/FORBIDDEN_IDOR_VIOLATION/);

      // User A is authorized and can run it
      const resultA = await ProofsService.verifyWithRealVision(uploadA.proofId, { minRepetitions: 0 }, userAId);
      expect(resultA.proofId).toBe(uploadA.proofId);
    });
  });

  describe('3. Rate Limiting Protection on Expensive Inference Endpoints', () => {
    it('permits requests within the rate limit threshold (10 per minute)', () => {
      for (let i = 0; i < 10; i++) {
        const check = SecurityService.checkRateLimit(`verify_vision_${userAId}`, 10, 60);
        expect(check.allowed).toBe(true);
      }
    });

    it('blocks the 11th request when rate limit is exceeded', () => {
      for (let i = 0; i < 10; i++) {
        SecurityService.checkRateLimit(`verify_vision_${userBId}`, 10, 60);
      }

      const blockedCheck = SecurityService.checkRateLimit(`verify_vision_${userBId}`, 10, 60);
      expect(blockedCheck.allowed).toBe(false);
      expect(blockedCheck.remaining).toBe(0);
    });

    it('isolates rate limits between different users', () => {
      // Max out User A
      for (let i = 0; i < 10; i++) {
        SecurityService.checkRateLimit(`verify_vision_${userAId}`, 10, 60);
      }
      expect(SecurityService.checkRateLimit(`verify_vision_${userAId}`, 10, 60).allowed).toBe(false);

      // User B is unaffected
      const userBCheck = SecurityService.checkRateLimit(`verify_vision_${userBId}`, 10, 60);
      expect(userBCheck.allowed).toBe(true);
    });
  });
});
