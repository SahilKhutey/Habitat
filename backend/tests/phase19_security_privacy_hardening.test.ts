// Habitat Phase 19 Security & Privacy Hardening Test Suite
import { describe, it, expect, beforeEach } from 'vitest';
import { SecurityService } from '../src/modules/security/security.service';
import { AuthSecurity } from '../src/modules/auth/auth.security';
import { SessionChallengeService } from '../src/modules/proofs/services/session-challenge.service';
import { EvidenceVerificationEngine } from '../src/modules/verification/engine/evidence-verification.engine';
import * as crypto from 'crypto';

describe('Phase 19: Security & Privacy Hardening Tests', () => {
  beforeEach(() => {
    SecurityService.clearAllForTesting();
    SessionChallengeService.resetForTesting();
  });

  describe('19.1: Authentication & Session Lifecycle', () => {
    it('creates active session and issues dual-token pair', () => {
      const userId = 'user_sec_01';
      const tokens = AuthSecurity.generateTokens(userId, 'user01@habitat.app');
      const session = SecurityService.createSession(userId, tokens.refreshToken);

      expect(session.state).toBe('ACTIVE');
      expect(session.userId).toBe(userId);

      const verified = SecurityService.getSessionByToken(tokens.refreshToken);
      expect(verified?.id).toBe(session.id);
    });

    it('revokes session and prevents subsequent token refresh', () => {
      const userId = 'user_sec_02';
      const tokens = AuthSecurity.generateTokens(userId, 'user02@habitat.app');
      const session = SecurityService.createSession(userId, tokens.refreshToken);

      const revoked = SecurityService.revokeSession(session.id);
      expect(revoked).toBe(true);

      const postRevokeSession = SecurityService.getSessionByToken(tokens.refreshToken);
      expect(postRevokeSession?.state).toBe('REVOKED');
    });

    it('marks expired session as EXPIRED', () => {
      const userId = 'user_sec_03';
      const tokens = AuthSecurity.generateTokens(userId, 'user03@habitat.app');
      // Create session expired in the past (-1 day)
      const session = SecurityService.createSession(userId, tokens.refreshToken, -1);

      const retrieved = SecurityService.getSessionByToken(tokens.refreshToken);
      expect(retrieved?.state).toBe('EXPIRED');
    });
  });

  describe('19.2: Authorization & IDOR Protection', () => {
    it('allows resource access when user is verified owner', () => {
      expect(() => {
        SecurityService.validateOwnership('user_001', 'user_001', 'Task');
      }).not.toThrow();
    });

    it('blocks foreign resource access and throws IDOR violation', () => {
      expect(() => {
        SecurityService.validateOwnership('attacker_user_999', 'victim_user_001', 'Mission');
      }).toThrow(/FORBIDDEN_IDOR_VIOLATION/);
    });
  });

  describe('19.3: Evidence Security & Anti-Replay Ledger', () => {
    it('accepts fresh single-use challenge and blocks replay attacks', () => {
      const userId = 'user_replay_01';
      const missionId = 'mission_replay_01';
      const challenge = SessionChallengeService.issueChallenge(missionId, userId);

      const payload = Buffer.from('TEST_CAMERA_EVIDENCE_BYTES');
      const sha256 = crypto.createHash('sha256').update(payload).digest('hex');

      // 1. First legitimate verification attempt
      const result1 = EvidenceVerificationEngine.verify({
        sessionId: challenge.sessionId,
        sessionNonce: challenge.sessionNonce,
        missionId,
        mediaType: 'VIDEO',
        mimeType: 'video/mp4',
        fileSizeBytes: 1024 * 1024 * 5,
        sha256,
        serverSha256: sha256,
        capturedAt: new Date().toISOString(),
        durationSeconds: 10,
      });

      expect(result1.decision).toBe('ACCEPT');

      // 2. Replay attack using identical nonce
      const result2 = EvidenceVerificationEngine.verify({
        sessionId: challenge.sessionId,
        sessionNonce: challenge.sessionNonce,
        missionId,
        mediaType: 'VIDEO',
        mimeType: 'video/mp4',
        fileSizeBytes: 1024 * 1024 * 5,
        sha256,
        serverSha256: sha256,
        capturedAt: new Date().toISOString(),
        durationSeconds: 10,
      });

      expect(result2.decision).toBe('REJECT');
      expect(result2.flags).toContain('REPLAY_NONCE_INVALID');
    });

    it('rejects cross-mission challenge submission', () => {
      const userId = 'user_cross_01';
      const challenge = SessionChallengeService.issueChallenge('mission_A', userId);

      const payload = Buffer.from('EVIDENCE');
      const sha256 = crypto.createHash('sha256').update(payload).digest('hex');

      const result = EvidenceVerificationEngine.verify({
        sessionId: challenge.sessionId,
        sessionNonce: challenge.sessionNonce,
        missionId: 'mission_B', // Mismatched mission
        mediaType: 'VIDEO',
        mimeType: 'video/mp4',
        fileSizeBytes: 1024 * 1024 * 5,
        sha256,
        serverSha256: sha256,
        capturedAt: new Date().toISOString(),
        durationSeconds: 10,
      });

      expect(result.decision).toBe('REJECT');
      expect(result.flags).toContain('MISSION_BINDING_MISMATCH');
    });
  });

  describe('19.4: Rate Limiting & Abuse Prevention', () => {
    it('throttles rapid requests exceeding rate limit threshold', () => {
      const rateLimitKey = 'ip_192_168_1_1_auth';
      const limit = 5;

      for (let i = 0; i < limit; i++) {
        const check = SecurityService.checkRateLimit(rateLimitKey, limit, 60);
        expect(check.allowed).toBe(true);
      }

      // 6th attempt in same window must be throttled
      const throttledCheck = SecurityService.checkRateLimit(rateLimitKey, limit, 60);
      expect(throttledCheck.allowed).toBe(false);
      expect(throttledCheck.remaining).toBe(0);
    });
  });

  describe('19.5: Structured Audit Trail & Privacy Sanitization', () => {
    it('records structured audit log without logging raw secrets', () => {
      const audit = SecurityService.recordAuditLog({
        eventType: 'PROOF_ACCEPTED',
        userId: 'user_aud_01',
        resourceId: 'mission_001',
        requestId: 'req_xyz_123',
        metadata: { repCount: 15, durationMs: 45000 },
      });

      expect(audit.id).toBeDefined();
      expect(audit.eventType).toBe('PROOF_ACCEPTED');
      expect(audit.requestId).toBe('req_xyz_123');

      const userLogs = SecurityService.getAuditLogs('user_aud_01');
      expect(userLogs.length).toBe(1);
    });

    it('sanitizes payload stripping passwords, tokens, and GPS coordinates', () => {
      const rawPayload = {
        userId: 'user_01',
        email: 'user@habitat.app',
        password: 'SuperSecretPassword123!',
        token: 'eyJhbGciOiJIUzI1Ni...',
        refreshToken: 'refresh_secret_token...',
        gps: { lat: 37.7749, lng: -122.4194 },
        waterMl: 500,
      };

      const sanitized = SecurityService.sanitizePayload(rawPayload);
      expect(sanitized.password).toBeUndefined();
      expect(sanitized.token).toBeUndefined();
      expect(sanitized.refreshToken).toBeUndefined();
      expect(sanitized.gps).toBeUndefined();
      expect(sanitized.waterMl).toBe(500);
      expect(sanitized.email).toBe('user@habitat.app');
    });
  });
});
