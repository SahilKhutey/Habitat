// Real Vision Adversarial Evaluator: Evaluates Media Corpus against Full Vision Stack
import { GeneratedFixtureData } from './media-generator';
import { VerificationEngine } from '../../../src/modules/verification/verification.engine';
import { EvidenceVerificationResult, VerificationEvidence } from '../../../src/modules/verification/domain/evidence.types';
import { SessionChallengeService } from '../../../src/modules/proofs/services/session-challenge.service';
import { VisionProviderFactory } from '../../../src/modules/verification/vision.factory';
import { VisionInput } from '../../../src/modules/verification/domain/vision-provider.interface';

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
   * Evaluates a real-media fixture through the end-to-end vision model and verification pipeline
   */
  public static async evaluate(fixture: GeneratedFixtureData): Promise<FixtureEvaluationMetrics> {
    const { metadata, frames } = fixture;

    // Issue cryptographic challenge for session
    const challenge = SessionChallengeService.issueChallenge(`m_${metadata.id}`, 'usr_evaluator_1');

    const isStaleReplayAttack = metadata.id === 'spoof_007_stale_replay_nonce_mismatch';
    const submittedNonce = isStaleReplayAttack ? 'EXPIRED_OLD_NONCE_VALUE' : challenge.sessionNonce;

    const visionInput: VisionInput = {
      sessionId: challenge.sessionId,
      taskSlug: 'tpl-pushups-10',
      frames: frames,
      startedAt: Date.now() - 5000,
      endedAt: Date.now()
    };

    const provider = VisionProviderFactory.getProvider();

    // 1. Run real neural network vision model on the fixture's raw pixel frame buffers
    let evidence: VerificationEvidence;
    if (typeof (provider as any).generateVerificationEvidence === 'function') {
      evidence = await (provider as any).generateVerificationEvidence(visionInput, submittedNonce);
    } else {
      const poseResult = await provider.detectPose(visionInput);
      evidence = {
        sessionId: challenge.sessionId,
        sessionNonce: submittedNonce,
        missionId: `mission_${metadata.id}`,
        taskSlug: 'tpl-pushups-10',
        startedAt: new Date(visionInput.startedAt).toISOString(),
        completedAt: new Date(visionInput.endedAt!).toISOString(),
        durationMs: 5000,
        pose: {
          model: provider.modelName,
          modelVersion: provider.modelVersion,
          totalFramesSampled: frames.length,
          meanPoseConfidence: poseResult.meanPoseConfidence,
          frameTrajectory: poseResult.detections.map((d) => ({
            frameIndex: d.frameIndex,
            timestampMs: d.timestampMs,
            frameHash: d.frameHash,
            keypoints: d.keypoints
          }))
        }
      };
    }

    // 2. Decision Engine Verification
    const verification: EvidenceVerificationResult = VerificationEngine.verifyEvidence(evidence, {
      minRepetitions: 0,
      skipNonceValidation: false
    });

    // 3. Invariant Validation
    // For Spoofs: MUST NOT ACCEPT (REJECT or REVIEW required)
    // For Genuine: MUST NOT REJECT (ACCEPT or REVIEW required)
    const securityInvariantPassed =
      metadata.groundTruth === 'spoof'
        ? verification.decision !== 'ACCEPT'
        : verification.decision !== 'REJECT';

    const meanConfidence = evidence.pose?.meanPoseConfidence ?? 0.0;
    const repsDetected = evidence.pose?.repsCalculated ?? 0;
    const livenessScore = evidence.liveness?.livenessScore ?? 0.0;

    return {
      fixtureId: metadata.id,
      fixtureName: metadata.name,
      category: metadata.category,
      groundTruth: metadata.groundTruth,
      frameCount: frames.length,
      poseConfidence: meanConfidence,
      repsDetected,
      frameUniquenessScore: evidence.liveness?.frameUniquenessScore ?? 0.0,
      temporalContinuityScore: evidence.liveness?.temporalContinuityScore ?? 0.0,
      motionContinuityScore: evidence.liveness?.motionContinuityScore ?? 0.0,
      replayRiskScore: evidence.liveness?.replayRiskScore ?? 0.0,
      livenessPassed: evidence.liveness?.challengePassed ?? (livenessScore >= 0.70),
      finalDecision: verification.decision,
      securityInvariantPassed,
      rejectionReason: verification.rejectionReason
    };
  }
}
