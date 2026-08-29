// Real Vision Adversarial Evaluator: Evaluates Media Corpus against Full Vision Stack
import { GeneratedFixtureData } from './media-generator';
import { PushupStateMachine } from '../../../src/modules/verification/domain/pushup-state-machine';
import { LivenessAnalyzer } from '../../../src/modules/verification/engine/liveness-analyzer';
import { VerificationEngine } from '../../../src/modules/verification/verification.engine';
import { EvidenceVerificationResult, VerificationEvidence } from '../../../src/modules/verification/domain/evidence.types';
import { SessionChallengeService } from '../../../src/modules/proofs/services/session-challenge.service';

export interface FixtureEvaluationMetrics {
  fixtureId: string;
  fixtureName: string;
  category: string;
  groundTruth: 'genuine' | 'spoof';
  frameCount: number;
  poseConfidence: number;
  repsDetected: number;
  frameUniquenessScore: number;
  temporalContinuityScore: number;
  motionContinuityScore: number;
  replayRiskScore: number;
  livenessPassed: boolean;
  finalDecision: 'ACCEPT' | 'REVIEW' | 'REJECT';
  securityInvariantPassed: boolean;
  rejectionReason: string | null;
}

export class RealVisionAdversarialEvaluator {
  /**
   * Evaluates a real-media fixture through the end-to-end verification pipeline
   */
  public static evaluate(fixture: GeneratedFixtureData): FixtureEvaluationMetrics {
    const { metadata, trajectory, sessionNonce } = fixture;

    // Issue cryptographic challenge for session
    const challenge = SessionChallengeService.issueChallenge(`m_${metadata.id}`, 'usr_evaluator_1');

    // 1. Biomechanical Repetition Counting
    const sm = new PushupStateMachine();
    const repStats = sm.feedTrajectory(trajectory);

    // 2. Multi-Signal Liveness & Anti-Spoof Analysis
    const liveness = LivenessAnalyzer.analyze(trajectory);

    // 3. Construct Full Verification Evidence
    const isStaleReplayAttack = metadata.id === 'spoof_007_stale_replay_nonce_mismatch';
    const submittedNonce = isStaleReplayAttack ? 'EXPIRED_OLD_NONCE_VALUE' : challenge.sessionNonce;

    const evidence: VerificationEvidence = {
      sessionId: challenge.sessionId,
      sessionNonce: submittedNonce,
      missionId: `mission_${metadata.id}`,
      taskSlug: 'tpl-pushups-10',
      startedAt: new Date(Date.now() - 22000).toISOString(),
      completedAt: new Date().toISOString(),
      durationMs: 22000,
      pose: {
        model: 'MoveNet-Lightning',
        modelVersion: '1.0.0',
        totalFramesSampled: trajectory.length,
        meanPoseConfidence: 0.90,
        frameTrajectory: trajectory,
        repsCalculated: repStats.validReps,
        shallowRepsCalculated: repStats.shallowReps,
        stateTransitions: repStats.stateTransitions
      },
      liveness: {
        livenessScore: liveness.livenessScore,
        temporalContinuityScore: liveness.temporalContinuityScore,
        frameUniquenessScore: liveness.frameUniquenessScore,
        trajectoryConsistencyScore: liveness.trajectoryConsistencyScore,
        motionContinuityScore: liveness.motionContinuityScore,
        replayRiskScore: liveness.replayRiskScore,
        challengePassed: liveness.isLivenessValid
      },
      integrity: {
        clientAppVersion: '1.0.0',
        evidencePayloadHash: `sha256_${metadata.id}_proof_hash`
      }
    };

    // 4. Decision Engine Verification
    const verification: EvidenceVerificationResult = VerificationEngine.verifyEvidence(evidence, {
      minRepetitions: 10,
      skipNonceValidation: false
    });

    // 5. Invariant Validation
    // For Spoofs: MUST NOT ACCEPT (REJECT or REVIEW required)
    // For Genuine: MUST NOT REJECT (ACCEPT or REVIEW required)
    const securityInvariantPassed =
      metadata.groundTruth === 'spoof'
        ? verification.decision !== 'ACCEPT'
        : verification.decision !== 'REJECT';

    return {
      fixtureId: metadata.id,
      fixtureName: metadata.name,
      category: metadata.category,
      groundTruth: metadata.groundTruth,
      frameCount: trajectory.length,
      poseConfidence: 0.90,
      repsDetected: repStats.validReps,
      frameUniquenessScore: liveness.frameUniquenessScore,
      temporalContinuityScore: liveness.temporalContinuityScore,
      motionContinuityScore: liveness.motionContinuityScore,
      replayRiskScore: liveness.replayRiskScore,
      livenessPassed: liveness.isLivenessValid,
      finalDecision: verification.decision,
      securityInvariantPassed,
      rejectionReason: verification.rejectionReason
    };
  }
}
