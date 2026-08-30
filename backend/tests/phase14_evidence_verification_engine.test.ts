// Phase 14 Authoritative Evidence Verification Engine Adversarial Test Suite
import { describe, it, expect, beforeEach } from 'vitest';
import { EvidenceVerificationEngine } from '../src/modules/verification/engine/evidence-verification.engine';
import { SessionChallengeService } from '../src/modules/proofs/services/session-challenge.service';

describe('Phase 14: Evidence Verification Engine Adversarial Matrix', () => {
  beforeEach(() => {
    SessionChallengeService.resetForTesting();
  });

  it('14.1: Accepts valid video evidence with active challenge and required repetitions', () => {
    const challenge = SessionChallengeService.issueChallenge('mission_pushups_01', 'user_01');

    const result = EvidenceVerificationEngine.verify(
      {
        sessionId: challenge.sessionId,
        sessionNonce: challenge.sessionNonce,
        missionId: 'mission_pushups_01',
        mediaType: 'VIDEO',
        mimeType: 'video/mp4',
        fileSizeBytes: 1024 * 1024 * 5,
        sha256: 'a'.repeat(64),
        serverSha256: 'a'.repeat(64),
        capturedAt: new Date().toISOString(),
        durationSeconds: 15,
        frames: [
          { frameIndex: 0, timestampMs: 0 },
          { frameIndex: 1, timestampMs: 33 },
          { frameIndex: 2, timestampMs: 66 },
          { frameIndex: 3, timestampMs: 100 }
        ],
        pose: { repsCalculated: 15 },
        liveness: { livenessScore: 0.95 }
      },
      {
        proofType: 'VIDEO',
        minDurationSeconds: 5,
        minRepetitions: 10
      }
    );

    expect(result.decision).toBe('ACCEPT');
    expect(result.accepted).toBe(true);
    expect(result.score).toBeGreaterThanOrEqual(0.9);
  });

  it('14.2: Rejects replayed session nonce on second submission', () => {
    const challenge = SessionChallengeService.issueChallenge('mission_pushups_02', 'user_01');

    // First attempt consumes nonce
    const firstResult = EvidenceVerificationEngine.verify({
      sessionId: challenge.sessionId,
      sessionNonce: challenge.sessionNonce,
      missionId: 'mission_pushups_02',
      mediaType: 'VIDEO',
      mimeType: 'video/mp4',
      capturedAt: new Date().toISOString(),
      durationSeconds: 10
    });
    expect(firstResult.decision).toBe('ACCEPT');

    // Second attempt with same nonce is rejected as replay
    const secondResult = EvidenceVerificationEngine.verify({
      sessionId: challenge.sessionId,
      sessionNonce: challenge.sessionNonce,
      missionId: 'mission_pushups_02',
      mediaType: 'VIDEO',
      mimeType: 'video/mp4',
      capturedAt: new Date().toISOString(),
      durationSeconds: 10
    });
    expect(secondResult.decision).toBe('REJECT');
    expect(secondResult.flags).toContain('REPLAY_NONCE_INVALID');
  });

  it('14.3: Rejects cross-mission replay (challenge bound to mission A used for mission B)', () => {
    const challenge = SessionChallengeService.issueChallenge('mission_A', 'user_01');

    const result = EvidenceVerificationEngine.verify({
      sessionId: challenge.sessionId,
      sessionNonce: challenge.sessionNonce,
      missionId: 'mission_B', // Mismatch!
      mediaType: 'VIDEO',
      mimeType: 'video/mp4',
      capturedAt: new Date().toISOString(),
      durationSeconds: 10
    });

    expect(result.decision).toBe('REJECT');
    expect(result.flags).toContain('MISSION_BINDING_MISMATCH');
  });

  it('14.4: Rejects SHA-256 hash tampering when client hash differs from server hash', () => {
    const result = EvidenceVerificationEngine.verify({
      mediaType: 'PHOTO',
      mimeType: 'image/jpeg',
      fileSizeBytes: 1024 * 200,
      sha256: 'a'.repeat(64),
      serverSha256: 'b'.repeat(64), // Mismatch!
      capturedAt: new Date().toISOString(),
      dimensions: { width: 1920, height: 1080 }
    });

    expect(result.decision).toBe('REJECT');
    expect(result.flags).toContain('HASH_TAMPERING_DETECTED');
  });

  it('14.5: Rejects gallery upload when live camera capture is enforced', () => {
    const result = EvidenceVerificationEngine.verify(
      {
        mediaType: 'PHOTO',
        mimeType: 'image/jpeg',
        isGalleryUpload: true,
        capturedAt: new Date().toISOString(),
        dimensions: { width: 1920, height: 1080 }
      },
      { allowGallery: false }
    );

    expect(result.decision).toBe('REJECT');
    expect(result.flags).toContain('GALLERY_UPLOAD_BLOCKED');
  });

  it('14.6: Rejects short video duration (< 5 seconds default)', () => {
    const result = EvidenceVerificationEngine.verify(
      {
        mediaType: 'VIDEO',
        mimeType: 'video/mp4',
        durationSeconds: 3, // Too short!
        capturedAt: new Date().toISOString()
      },
      { minDurationSeconds: 5 }
    );

    expect(result.decision).toBe('REJECT');
    expect(result.flags).toContain('VIDEO_DURATION_INVALID');
  });

  it('14.7: Rejects non-monotonic / spliced video frame timeline', () => {
    const result = EvidenceVerificationEngine.verify({
      mediaType: 'VIDEO',
      mimeType: 'video/mp4',
      durationSeconds: 10,
      capturedAt: new Date().toISOString(),
      frames: [
        { frameIndex: 0, timestampMs: 0 },
        { frameIndex: 1, timestampMs: 33 },
        { frameIndex: 0, timestampMs: 20 }, // Spliced/Reversed!
        { frameIndex: 3, timestampMs: 100 }
      ]
    });

    expect(result.decision).toBe('REJECT');
    expect(result.flags).toContain('FRAME_SEQUENCE_MANIPULATED');
  });

  it('14.8: Rejects insufficient physical repetitions', () => {
    const result = EvidenceVerificationEngine.verify(
      {
        mediaType: 'VIDEO',
        mimeType: 'video/mp4',
        durationSeconds: 20,
        capturedAt: new Date().toISOString(),
        pose: { repsCalculated: 6 } // Required 10
      },
      { minRepetitions: 10 }
    );

    expect(result.decision).toBe('REJECT');
    expect(result.flags).toContain('INSUFFICIENT_REPETITIONS');
  });

  it('14.9: Rejects stale evidence captured > 180 seconds ago', () => {
    const staleDate = new Date(Date.now() - 300 * 1000).toISOString(); // 5 min ago

    const result = EvidenceVerificationEngine.verify({
      mediaType: 'PHOTO',
      mimeType: 'image/jpeg',
      capturedAt: staleDate,
      dimensions: { width: 1920, height: 1080 }
    });

    expect(result.decision).toBe('REJECT');
    expect(result.flags).toContain('STALE_EVIDENCE_TIMESTAMP');
  });

  it('14.10: Rejects undersized photo dimensions (< 320x240)', () => {
    const result = EvidenceVerificationEngine.verify({
      mediaType: 'PHOTO',
      mimeType: 'image/jpeg',
      capturedAt: new Date().toISOString(),
      dimensions: { width: 100, height: 100 } // Undersized!
    });

    expect(result.decision).toBe('REJECT');
    expect(result.flags).toContain('PHOTO_DIMENSIONS_UNDERSIZED');
  });

  it('14.11: Rejects evidence when required object labels are missing', () => {
    const result = EvidenceVerificationEngine.verify(
      {
        mediaType: 'PHOTO',
        mimeType: 'image/jpeg',
        capturedAt: new Date().toISOString(),
        dimensions: { width: 1920, height: 1080 },
        detectedLabels: ['glass'] // Missing 'water'!
      },
      { requiredLabels: ['glass', 'water'] }
    );

    expect(result.decision).toBe('REJECT');
    expect(result.flags).toContain('REQUIRED_OBJECTS_MISSING');
  });

  it('14.12: Rejects future timestamps beyond clock skew tolerance', () => {
    const futureDate = new Date(Date.now() + 120 * 1000).toISOString(); // 2 min in future

    const result = EvidenceVerificationEngine.verify({
      mediaType: 'PHOTO',
      mimeType: 'image/jpeg',
      capturedAt: futureDate,
      dimensions: { width: 1920, height: 1080 }
    });

    expect(result.decision).toBe('REJECT');
    expect(result.flags).toContain('FUTURE_TIMESTAMP_DETECTED');
  });
});
