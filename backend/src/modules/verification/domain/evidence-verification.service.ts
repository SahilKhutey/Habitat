// Authoritative Production Verification Service Orchestrator
import { v4 as uuidv4 } from 'uuid';
import { DatabaseService } from '../../../db/connection';
import { ProofValidator, ProofValidationResult } from '../services/proof-validator';
import { FrameExtractor } from '../infrastructure/video-frame-extractor';
import { VisionProviderFactory } from '../vision.factory';
import { VisionInput, VisionFrame } from '../domain/vision-provider.interface';
import { PoseQualityFilter } from '../engine/pose-quality.filter';
import { PoseGeometryCalculator } from '../engine/pose-geometry.calculator';
import { ReplayDetector } from '../engine/replay-detector';
import { LivenessAnalyzer } from '../engine/liveness-analyzer';
import { PushUpEvaluator } from '../evaluators/pushup-evaluator';
import { DecisionEngine } from '../engine/decision-engine';
import { VerificationDecision } from '../domain/verification-status.enum';
import { VerificationCheck, VerificationReason } from '../domain/verification-reason.enum';
import { SessionChallengeService } from '../../proofs/services/session-challenge.service';
import { FramePoseRecord } from '../domain/evidence.types';
import { MissionService } from '../../missions/domain/mission.service';

export interface VerifyProofParams {
  proofId: string;
  missionId: string;
  userId: string;
  sessionId?: string;
  sessionNonce?: string;
  targetReps?: number;
  exerciseType?: 'PUSH_UP' | string;
}

export interface VerificationExecutionResult {
  verificationId: string;
  decision: 'ACCEPT' | 'REVIEW' | 'REJECT';
  confidence: number;
  reasons: string[];
  checks: Array<{ name: string; passed: boolean; confidence?: number }>;
  repsDetected: number;
  targetReps: number;
  livenessScore: number;
  missionStatus: string;
  xpAwarded?: number;
}

export class EvidenceVerificationService {
  private readonly missionService: MissionService;

  constructor(missionService?: MissionService) {
    this.missionService = missionService || new MissionService();
  }

  /**
   * Authoritative production verification pipeline:
   * Validates file -> extracts frames -> runs MoveNet -> filters pose -> detects replay/liveness -> evaluates biomechanics -> renders tri-state decision -> persists record.
   */
  public async verifyProof(params: VerifyProofParams): Promise<VerificationExecutionResult> {
    const db = DatabaseService.getDb();
    const verificationId = uuidv4();
    const startedAt = new Date().toISOString();
    const checks: VerificationCheck[] = [];
    const reasons: VerificationReason[] = [];

    // --- STEP 1: Proof File & Identity Validation ---
    const validationResult: ProofValidationResult = await ProofValidator.validate({
      proofId: params.proofId,
      missionId: params.missionId,
      userId: params.userId
    });

    if (!validationResult.isValid) {
      checks.push({
        name: 'PROOF_FILE_INTEGRITY',
        passed: false,
        confidence: 0.0,
        details: { code: validationResult.code, reason: validationResult.reason }
      });
      reasons.push(VerificationReason.TAMPERING_DETECTED);

      return this.persistAndFailClosed({
        verificationId,
        proofId: params.proofId,
        missionId: params.missionId,
        userId: params.userId,
        decision: VerificationDecision.REJECT,
        confidence: 0.0,
        reasons: [validationResult.reason],
        checks,
        startedAt
      });
    }

    checks.push({
      name: 'PROOF_FILE_INTEGRITY',
      passed: true,
      confidence: 1.0
    });

    // --- STEP 2: Session Nonce & Replay Challenge Binding ---
    if (params.sessionId && params.sessionNonce) {
      const challengeResult = SessionChallengeService.validateAndConsumeNonce(
        params.sessionId,
        params.sessionNonce
      );

      if (!challengeResult.isValid) {
        checks.push({
          name: 'SESSION_NONCE_BINDING',
          passed: false,
          confidence: 0.0,
          details: { reason: challengeResult.reason }
        });
        reasons.push(VerificationReason.TAMPERING_DETECTED);

        return this.persistAndFailClosed({
          verificationId,
          proofId: params.proofId,
          missionId: params.missionId,
          userId: params.userId,
          decision: VerificationDecision.REJECT,
          confidence: 0.0,
          reasons: [challengeResult.reason || 'Cryptographic session nonce invalid or already consumed.'],
          checks,
          startedAt
        });
      }

      // Validate mission binding
      if (challengeResult.challenge && challengeResult.challenge.missionId !== params.missionId) {
        checks.push({
          name: 'SESSION_NONCE_BINDING',
          passed: false,
          confidence: 0.0,
          details: { reason: 'Nonce mission binding mismatch' }
        });
        reasons.push(VerificationReason.TAMPERING_DETECTED);

        return this.persistAndFailClosed({
          verificationId,
          proofId: params.proofId,
          missionId: params.missionId,
          userId: params.userId,
          decision: VerificationDecision.REJECT,
          confidence: 0.0,
          reasons: ['Session nonce belongs to a different mission.'],
          checks,
          startedAt
        });
      }

      checks.push({
        name: 'SESSION_NONCE_BINDING',
        passed: true,
        confidence: 1.0
      });
    }

    // --- STEP 3: Frame Extraction Pipeline (FFmpeg) ---
    const frameExtractor = new FrameExtractor();
    let visionFrames: VisionFrame[] = [];

    try {
      visionFrames = await frameExtractor.extractVisionFrames(validationResult.bytes);
    } catch (err: any) {
      checks.push({
        name: 'FRAME_EXTRACTION',
        passed: false,
        confidence: 0.0,
        details: { error: err.message }
      });
      reasons.push(VerificationReason.UNSUPPORTED_MEDIA_FORMAT);

      return this.persistAndFailClosed({
        verificationId,
        proofId: params.proofId,
        missionId: params.missionId,
        userId: params.userId,
        decision: VerificationDecision.REJECT,
        confidence: 0.0,
        reasons: [`FFmpeg frame extraction failed: ${err.message}`],
        checks,
        startedAt
      });
    }

    if (visionFrames.length === 0) {
      return this.persistAndFailClosed({
        verificationId,
        proofId: params.proofId,
        missionId: params.missionId,
        userId: params.userId,
        decision: VerificationDecision.REJECT,
        confidence: 0.0,
        reasons: ['Video contains 0 decodable frames.'],
        checks,
        startedAt
      });
    }

    checks.push({
      name: 'FRAME_EXTRACTION',
      passed: true,
      confidence: 1.0,
      details: { framesExtracted: visionFrames.length }
    });

    // --- STEP 4: MoveNet Pose Inference ---
    const visionProvider = VisionProviderFactory.getProvider();
    const visionInput: VisionInput = {
      sessionId: params.sessionId || uuidv4(),
      taskSlug: params.exerciseType || 'pushup-discipline',
      frames: visionFrames,
      startedAt: Date.now() - visionFrames.length * 100,
      endedAt: Date.now()
    };

    let poseDetectionResult;
    try {
      poseDetectionResult = await visionProvider.detectPose(visionInput);
    } catch (err: any) {
      // FAIL CLOSED: Vision failure never defaults to accept
      checks.push({
        name: 'VISION_INFERENCE',
        passed: false,
        confidence: 0.0,
        details: { error: err.message }
      });

      return this.persistAndFailClosed({
        verificationId,
        proofId: params.proofId,
        missionId: params.missionId,
        userId: params.userId,
        decision: VerificationDecision.REVIEW,
        confidence: 0.1,
        reasons: [`Vision model inference error: ${err.message}. Queued for review.`],
        checks,
        startedAt
      });
    }

    // --- STEP 5: Pose Quality Filter & Normalization ---
    const rawTrajectory: FramePoseRecord[] = poseDetectionResult.detections.map((d) => {
      const geometry = PoseGeometryCalculator.calculateMetrics(d.keypoints);
      return {
        frameIndex: d.frameIndex,
        timestampMs: d.timestampMs,
        frameHash: d.frameHash,
        keypoints: d.keypoints,
        leftElbowAngleDeg: geometry.leftElbowAngleDeg,
        rightElbowAngleDeg: geometry.rightElbowAngleDeg,
        bodyAlignmentAngleDeg: geometry.bodyAlignmentAngleDeg
      };
    });

    const qualityResult = PoseQualityFilter.filterSequence(rawTrajectory);
    checks.push({
      name: 'POSE_LANDMARK_QUALITY',
      passed: qualityResult.isQualitySufficient,
      confidence: qualityResult.qualityRatio,
      details: {
        validFrames: qualityResult.validFrames.length,
        totalFrames: qualityResult.totalFrames,
        discarded: qualityResult.discardedFramesCount
      }
    });

    if (!qualityResult.isQualitySufficient) {
      reasons.push(VerificationReason.POSE_CONFIDENCE_TOO_LOW);
    }

    // --- STEP 6: Replay Detection & Liveness Subsystem ---
    const replayResult = ReplayDetector.detect(
      rawTrajectory.map((f) => ({
        timestampMs: f.timestampMs,
        frameHash: f.frameHash,
        keypoints: f.keypoints
      }))
    );

    checks.push({
      name: 'REPLAY_DETECTION',
      passed: !replayResult.replayDetected,
      confidence: 1.0 - replayResult.replayRiskScore,
      details: replayResult.metrics
    });

    if (replayResult.replayDetected) {
      reasons.push(VerificationReason.TAMPERING_DETECTED);
    }

    const livenessResult = LivenessAnalyzer.analyze(rawTrajectory);
    checks.push({
      name: 'LIVENESS_ANALYSIS',
      passed: livenessResult.isLivenessValid,
      confidence: livenessResult.livenessScore,
      details: {
        score: livenessResult.livenessScore,
        continuity: livenessResult.temporalContinuityScore,
        uniqueness: livenessResult.frameUniquenessScore
      }
    });

    if (!livenessResult.isLivenessValid) {
      reasons.push(VerificationReason.STATIC_IMAGE_DETECTED);
    }

    // --- STEP 7: Exercise Biomechanical & Temporal Evaluator ---
    const targetReps = params.targetReps ?? 10;
    const evaluator = new PushUpEvaluator();
    const evaluatorResult = evaluator.evaluate(qualityResult.validFrames, { targetReps });

    checks.push({
      name: 'EXERCISE_REPETITION_COUNT',
      passed: evaluatorResult.passed,
      confidence: evaluatorResult.repsDetected >= targetReps ? 0.95 : 0.20,
      details: {
        repsDetected: evaluatorResult.repsDetected,
        targetReps,
        shallowReps: evaluatorResult.metrics.shallowRepsCount
      }
    });

    if (!evaluatorResult.passed) {
      reasons.push(VerificationReason.INSUFFICIENT_REPETITIONS);
    }

    // --- STEP 8: Decision Engine Evaluation ---
    const baseConfidence =
      (poseDetectionResult.meanPoseConfidence * 0.35) +
      (livenessResult.livenessScore * 0.35) +
      (evaluatorResult.formQualityScore * 0.30);

    const decisionResult = DecisionEngine.decide(
      baseConfidence,
      checks,
      reasons
    );

    const completedAt = new Date().toISOString();
    const finalDecisionStr = decisionResult.decision;

    // --- STEP 9: Persist in Database (Audit Trail) ---
    const allReasons = Array.from(new Set([
      ...reasons.map(String),
      ...evaluatorResult.reasons,
      ...replayResult.reasons
    ]));

    db.prepare(`
      INSERT INTO verifications (id, proof_id, mission_id, user_id, status, decision, confidence, verifier, verifier_version, reasons, checks, started_at, completed_at, created_at)
      VALUES (?, ?, ?, ?, 'COMPLETED', ?, ?, 'MoveNet-Lightning', '1.0.0', ?, ?, ?, ?, ?)
    `).run(
      verificationId,
      params.proofId,
      params.missionId,
      params.userId,
      finalDecisionStr,
      decisionResult.confidence,
      JSON.stringify(allReasons),
      JSON.stringify(checks),
      startedAt,
      completedAt,
      completedAt
    );

    // Update proof asset record
    db.prepare(`
      UPDATE proofs 
      SET verification_status = ?, verified_at = ?, rejection_reason = ?
      WHERE id = ?
    `).run(
      finalDecisionStr,
      completedAt,
      allReasons.length > 0 ? allReasons.join('; ') : null,
      params.proofId
    );

    // --- STEP 10: Real Completion Boundary ---
    let missionStatus = 'VERIFYING';
    let xpAwarded: number | undefined;

    if (finalDecisionStr === 'ACCEPT') {
      // Authoritative transactional mission completion
      const completion = this.missionService.completeMission({
        missionId: params.missionId,
        userId: params.userId,
        resistanceSeconds: 15,
        baseXp: 50,
        idempotencyKey: `verify_complete_${params.proofId}`
      });
      missionStatus = 'COMPLETED';
      xpAwarded = completion.xpAwarded;
    } else if (finalDecisionStr === 'REJECT') {
      // Trigger escalation retry
      await this.missionService.retryMission(params.missionId, allReasons.join(', '));
      missionStatus = 'ACTIVE';
    } else {
      missionStatus = 'REVIEW_REQUIRED';
    }

    return {
      verificationId,
      decision: finalDecisionStr as 'ACCEPT' | 'REVIEW' | 'REJECT',
      confidence: decisionResult.confidence,
      reasons: allReasons,
      checks: checks.map((c) => ({ name: c.name, passed: c.passed, confidence: c.confidence })),
      repsDetected: evaluatorResult.repsDetected,
      targetReps,
      livenessScore: livenessResult.livenessScore,
      missionStatus,
      xpAwarded
    };
  }

  private persistAndFailClosed(params: {
    verificationId: string;
    proofId: string;
    missionId: string;
    userId: string;
    decision: VerificationDecision;
    confidence: number;
    reasons: string[];
    checks: VerificationCheck[];
    startedAt: string;
  }): VerificationExecutionResult {
    const db = DatabaseService.getDb();
    const completedAt = new Date().toISOString();

    const missionExists = db.prepare('SELECT id FROM missions WHERE id = ?').get(params.missionId);
    if (missionExists) {
      db.prepare(`
        INSERT INTO verifications (id, proof_id, mission_id, user_id, status, decision, confidence, verifier, verifier_version, reasons, checks, started_at, completed_at, created_at)
        VALUES (?, ?, ?, ?, 'COMPLETED', ?, ?, 'MoveNet-Lightning', '1.0.0', ?, ?, ?, ?, ?)
      `).run(
        params.verificationId,
        params.proofId,
        params.missionId,
        params.userId,
        params.decision,
        params.confidence,
        JSON.stringify(params.reasons),
        JSON.stringify(params.checks),
        params.startedAt,
        completedAt,
        completedAt
      );

      db.prepare(`
        UPDATE proofs 
        SET verification_status = ?, verified_at = ?, rejection_reason = ?
        WHERE id = ?
      `).run(
        params.decision,
        completedAt,
        params.reasons.join('; '),
        params.proofId
      );
    }

    return {
      verificationId: params.verificationId,
      decision: params.decision as 'ACCEPT' | 'REVIEW' | 'REJECT',
      confidence: params.confidence,
      reasons: params.reasons,
      checks: params.checks.map((c) => ({ name: c.name, passed: c.passed, confidence: c.confidence })),
      repsDetected: 0,
      targetReps: 10,
      livenessScore: 0.0,
      missionStatus: params.decision === VerificationDecision.REJECT ? 'ACTIVE' : 'REVIEW_REQUIRED'
    };
  }
}
