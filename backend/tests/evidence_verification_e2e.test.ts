// End-to-End Verification & Anti-Cheat Evidence Engine Test Suite
import { describe, it, expect, beforeEach } from 'vitest';
import { VerificationEngine } from '../src/modules/verification/verification.engine';
import { SessionChallengeService } from '../src/modules/proofs/services/session-challenge.service';
import { VerificationEvidence, FramePoseRecord } from '../src/modules/verification/domain/evidence.types';

describe('End-to-End Evidence-Driven Verification Pipeline', () => {
  const missionId = 'mission-pushups-today-001';
  const userId = 'user-soldier-777';

  beforeEach(() => {
    SessionChallengeService.resetForTesting();
  });

  // Helper to construct a realistic 10-pushup evidence packet
  function createPushupEvidence(
    sessionId: string,
    sessionNonce: string,
    reps: number = 10,
    options: {
      isStaticPhoto?: boolean;
      minDepthElbow?: number; // 80 is deep, 120 is shallow
      bodyAlignment?: number;
      fps?: number;
    } = {}
  ): VerificationEvidence {
    const isStatic = options.isStaticPhoto ?? false;
    const minDepth = options.minDepthElbow ?? 80;
    const alignment = options.bodyAlignment ?? 170;
    const fps = options.fps ?? 30;

    const framesPerRep = 30; // 1s per rep
    const totalFrames = isStatic ? 30 : reps * framesPerRep;
    const trajectory: FramePoseRecord[] = [];

    for (let i = 0; i < totalFrames; i++) {
      const timestampMs = Math.round(i * (1000 / fps));
      let elbowAngle = 165;

      if (!isStatic) {
        const repProgress = (i % framesPerRep) / framesPerRep;
        // Sine curve between 165 lockout and minDepth
        const depthDelta = 165 - minDepth;
        elbowAngle = 165 - depthDelta * Math.sin(repProgress * Math.PI);
      }

      const frameHash = isStatic
        ? 'static_photo_constant_frame_hash_digest'
        : `hash_frame_${i}_angle_${Math.round(elbowAngle)}`;

      trajectory.push({
        timestampMs,
        frameIndex: i,
        frameHash,
        keypoints: [
          { name: 'left_shoulder', x: 0.4, y: 0.3, score: 0.95 },
          { name: 'left_elbow', x: 0.4, y: 0.45, score: 0.95 },
          { name: 'left_wrist', x: 0.4, y: 0.6, score: 0.95 },
          { name: 'right_shoulder', x: 0.6, y: 0.3, score: 0.95 },
          { name: 'right_elbow', x: 0.6, y: 0.45, score: 0.95 },
          { name: 'right_wrist', x: 0.6, y: 0.6, score: 0.95 },
          { name: 'left_hip', x: 0.42, y: 0.65, score: 0.92 },
          { name: 'right_hip', x: 0.58, y: 0.65, score: 0.92 },
          { name: 'left_ankle', x: 0.44, y: 0.90, score: 0.90 },
          { name: 'right_ankle', x: 0.56, y: 0.90, score: 0.90 }
        ],
        leftElbowAngleDeg: elbowAngle,
        rightElbowAngleDeg: elbowAngle,
        bodyAlignmentAngleDeg: alignment
      });
    }

    return {
      sessionId,
      sessionNonce,
      missionId,
      taskSlug: 'tpl-pushups-10',
      startedAt: new Date(Date.now() - totalFrames * 33).toISOString(),
      completedAt: new Date().toISOString(),
      durationMs: totalFrames * 33,
      pose: {
        model: 'MoveNet-Lightning-TFLite',
        modelVersion: '1.0.0',
        totalFramesSampled: trajectory.length,
        meanPoseConfidence: 0.95,
        frameTrajectory: trajectory,
        repsCalculated: reps,
        shallowRepsCalculated: 0,
        stateTransitions: []
      },
      liveness: {
        livenessScore: 0.95,
        temporalContinuityScore: 1.0,
        frameUniquenessScore: 1.0,
        trajectoryConsistencyScore: 0.95,
        motionContinuityScore: 1.0,
        replayRiskScore: 0.0,
        challengePassed: true
      },
      integrity: {
        clientAppVersion: '1.0.0',
        evidencePayloadHash: 'valid_payload_hash_sha256'
      }
    };
  }

  it('ACCEPT: authentic 10 push-ups with fresh cryptographic nonce disarms mission', () => {
    // 1. Backend issues challenge nonce
    const challenge = SessionChallengeService.issueChallenge(missionId, userId);
    expect(challenge.sessionId).toBeDefined();
    expect(challenge.sessionNonce.length).toBe(64); // 256-bit hex

    // 2. Client completes physical mission and submits evidence
    const evidence = createPushupEvidence(challenge.sessionId, challenge.sessionNonce, 10, {
      minDepthElbow: 80,
      bodyAlignment: 170
    });

    // 3. Backend verifies evidence
    const result = VerificationEngine.verifyEvidence(evidence, { minRepetitions: 10 });

    expect(result.decision).toBe('ACCEPT');
    expect(result.truthScore).toBeGreaterThanOrEqual(0.85);
    expect(result.repsVerified).toBe(10);
    expect(result.repsRequired).toBe(10);
    expect(result.rejectionReason).toBeNull();
    expect(result.breakdown.repetitionScore).toBe(1.0);
    expect(result.breakdown.livenessScore).toBeGreaterThanOrEqual(0.80);
    expect(result.breakdown.integrityScore).toBe(1.0);
  });

  it('REJECT: static photograph attack is blocked by liveness analyzer', () => {
    const challenge = SessionChallengeService.issueChallenge(missionId, userId);
    const staticEvidence = createPushupEvidence(challenge.sessionId, challenge.sessionNonce, 0, {
      isStaticPhoto: true
    });

    const result = VerificationEngine.verifyEvidence(staticEvidence, { minRepetitions: 10 });

    expect(result.decision).toBe('REJECT');
    expect(result.flags).toContain('STATIC_PHOTO_OR_FROZEN_FRAME');
    expect(result.rejectionReason).toContain('Static photograph');
  });

  it('REJECT: shallow push-ups failing full depth (<90 deg) are rejected', () => {
    const challenge = SessionChallengeService.issueChallenge(missionId, userId);
    // Arms only bend to 120 degrees (never reach 90 deg depth)
    const shallowEvidence = createPushupEvidence(challenge.sessionId, challenge.sessionNonce, 10, {
      minDepthElbow: 120
    });

    const result = VerificationEngine.verifyEvidence(shallowEvidence, { minRepetitions: 10 });

    expect(result.decision).toBe('REJECT');
    expect(result.repsVerified).toBe(0);
    expect(result.rejectionReason).toContain('Insufficient valid repetitions');
  });

  it('REJECT: replay attack reusing an already-consumed session nonce is blocked', () => {
    const challenge = SessionChallengeService.issueChallenge(missionId, userId);

    const evidence1 = createPushupEvidence(challenge.sessionId, challenge.sessionNonce, 10);
    const result1 = VerificationEngine.verifyEvidence(evidence1, { minRepetitions: 10 });
    expect(result1.decision).toBe('ACCEPT');

    // Attempt second submission with same consumed nonce
    const evidenceReplay = createPushupEvidence(challenge.sessionId, challenge.sessionNonce, 10);
    const result2 = VerificationEngine.verifyEvidence(evidenceReplay, { minRepetitions: 10 });

    expect(result2.decision).toBe('REJECT');
    expect(result2.flags).toContain('INVALID_OR_REPLAYED_SESSION_NONCE');
    expect(result2.rejectionReason).toContain('already consumed');
  });

  it('REVIEW / REJECT: partial repetitions (e.g. 5 of 10) triggers appropriate review or rejection', () => {
    const challenge = SessionChallengeService.issueChallenge(missionId, userId);
    const halfEvidence = createPushupEvidence(challenge.sessionId, challenge.sessionNonce, 5, {
      minDepthElbow: 80
    });

    const result = VerificationEngine.verifyEvidence(halfEvidence, { minRepetitions: 10 });

    expect(['REJECT', 'REVIEW']).toContain(result.decision);
    expect(result.repsVerified).toBe(5);
    expect(result.rejectionReason).toBeDefined();
  });
});
