// Phase 9 Authoritative Verification & Truth Service
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { MissionsService } from '../missions/missions.controller';
import { ProofsService } from '../proofs/proofs.controller';
import { AntiCheatValidator } from './domain/anti-cheat.validator';
import { CvLabelDetector } from './domain/cv-label.detector';
import { PoseRepCounter } from './domain/pose-rep.counter';
import { VerificationEvaluationResult, VerificationStrategy } from './domain/verification.types';
import { VisionProviderFactory } from './vision.factory';
import { VisionInput, VisionFrame } from './domain/vision-provider.interface';
import { VerificationEngine } from './verification.engine';
import { EvidenceVerificationResult, VerificationEvidence, FramePoseRecord } from './domain/evidence.types';
import { SessionChallengeService } from '../proofs/services/session-challenge.service';
import { PoseGeometryCalculator } from './engine/pose-geometry.calculator';
import { PushupStateMachine } from './domain/pushup-state-machine';
import { LivenessAnalyzer } from './engine/liveness-analyzer';

export class VerificationTruthService {
  /**
   * Authoritative Server-Side Media Verification:
   * Accepts raw video frames/buffers, executes server-side MoveNet pose estimation,
   * generates authoritative VerificationEvidence, and verifies with EvidenceVerificationEngine.
   */
  public static async evaluateMediaProof(params: {
    missionId: string;
    proofId?: string;
    sessionId: string;
    sessionNonce: string;
    taskSlug: string;
    frames: VisionFrame[];
    startedAt?: number;
    endedAt?: number;
    policy?: { minRepetitions?: number; minLivenessScore?: number; skipNonceValidation?: boolean };
  }): Promise<{
    verification: EvidenceVerificationResult;
    evidence: VerificationEvidence;
    missionStatus: string;
    xpAwarded: number;
  }> {
    const provider = VisionProviderFactory.getProvider();
    const visionInput: VisionInput = {
      sessionId: params.sessionId,
      taskSlug: params.taskSlug,
      frames: params.frames,
      startedAt: params.startedAt || Date.now() - 5000,
      endedAt: params.endedAt || Date.now()
    };

    // 1. Run authoritative server-side MoveNet inference and generate evidence
    let evidence: VerificationEvidence;
    if (typeof (provider as any).generateVerificationEvidence === 'function') {
      evidence = await (provider as any).generateVerificationEvidence(visionInput, params.sessionNonce);
    } else {
      const poseResult = await provider.detectPose(visionInput);
      const frameTrajectory: FramePoseRecord[] = poseResult.detections.map((d) => {
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
      const sm = new PushupStateMachine();
      const repStats = sm.feedTrajectory(frameTrajectory);
      const livenessResult = LivenessAnalyzer.analyze(frameTrajectory);

      evidence = {
        sessionId: params.sessionId,
        sessionNonce: params.sessionNonce,
        missionId: params.missionId,
        taskSlug: params.taskSlug,
        startedAt: new Date(visionInput.startedAt).toISOString(),
        completedAt: new Date(visionInput.endedAt!).toISOString(),
        durationMs: (visionInput.endedAt || Date.now()) - visionInput.startedAt,
        pose: {
          model: provider.modelName,
          modelVersion: provider.modelVersion,
          totalFramesSampled: params.frames.length,
          meanPoseConfidence: poseResult.meanPoseConfidence,
          frameTrajectory,
          repsCalculated: repStats.validReps,
          shallowRepsCalculated: repStats.shallowReps,
          stateTransitions: repStats.stateTransitions
        },
        liveness: {
          livenessScore: livenessResult.livenessScore,
          temporalContinuityScore: livenessResult.temporalContinuityScore,
          frameUniquenessScore: livenessResult.frameUniquenessScore,
          trajectoryConsistencyScore: livenessResult.trajectoryConsistencyScore,
          motionContinuityScore: livenessResult.motionContinuityScore,
          replayRiskScore: livenessResult.replayRiskScore,
          challengePassed: livenessResult.isLivenessValid
        },
        integrity: {
          clientAppVersion: '1.0.0',
          evidencePayloadHash: `sha256_${params.sessionId}`
        }
      };
    }

    // 2. Evaluate with Authoritative VerificationEngine
    const verification = VerificationEngine.verifyEvidence(evidence, params.policy);

    // 3. Persist and trigger state transitions
    if (verification.decision === 'ACCEPT') {
      const acc = this.handleAcceptance({
        missionId: params.missionId,
        proofId: params.proofId,
        strategy: 'POSE_ESTIMATION_REPS',
        confidence: verification.truthScore,
        metrics: {
          repsCounted: evidence.pose?.repsCalculated ?? 0,
          livenessScore: evidence.liveness?.livenessScore ?? 1.0,
          flags: verification.flags
        }
      });
      return {
        verification,
        evidence,
        missionStatus: acc.missionStatus,
        xpAwarded: acc.xpAwarded
      };
    } else {
      const rej = this.handleRejection({
        missionId: params.missionId,
        proofId: params.proofId,
        strategy: 'POSE_ESTIMATION_REPS',
        reason: verification.rejectionReason || 'Physical mission criteria not met.',
        advice: 'Ensure full range of motion and good lighting.',
        metrics: {
          flags: verification.flags,
          livenessScore: evidence.liveness?.livenessScore ?? 0.0
        }
      });
      return {
        verification,
        evidence,
        missionStatus: rej.missionStatus,
        xpAwarded: 0
      };
    }
  }

  /**
   * Evaluates submitted proof against task-specific truth models and anti-cheat heuristics
   */
  public static evaluateProof(params: {
    missionId: string;
    proofId?: string;
    telemetry?: {
      ambientLux?: number;
      entropyScore?: number;
      detectedLabels?: string[];
      motionCycles?: number;
      poseConfidence?: number;
      isGalleryUpload?: boolean;
      capturedAt?: string;
    };
  }): VerificationEvaluationResult & { missionStatus: string; xpAwarded: number } {
    const db = DatabaseService.getDb();
    const mission = MissionsService.getById(params.missionId);
    if (!mission) throw new Error('MISSION_NOT_FOUND: Mission not found');

    // 1. Resolve Proof Record
    let proof: any = null;
    if (params.proofId) {
      proof = ProofsService.getById(params.proofId);
    } else {
      proof = db.prepare('SELECT * FROM proofs WHERE mission_id = ? ORDER BY created_at DESC LIMIT 1').get(params.missionId);
    }

    const taskRow = db.prepare('SELECT * FROM tasks WHERE id = ?').get(mission.taskId) as any;
    const taskRules = taskRow?.validation_rules ? JSON.parse(taskRow.validation_rules) : {};
    const taskCategory = taskRow?.category || 'GENERAL';

    const capturedAt = params.telemetry?.capturedAt || proof?.capturedAt || proof?.captured_at || new Date().toISOString();
    const ambientLux = params.telemetry?.ambientLux ?? proof?.deviceTelemetry?.ambientLux ?? proof?.deviceTelemetry?.luminanceScore ?? 50;
    const entropyScore = params.telemetry?.entropyScore ?? proof?.deviceTelemetry?.entropyScore ?? 0.85;
    const isGallery = params.telemetry?.isGalleryUpload ?? proof?.deviceTelemetry?.isGalleryUpload ?? false;

    // 2. Anti-Cheat Checks
    // A. Freshness Check (<= 180s)
    const freshness = AntiCheatValidator.validateFreshness(capturedAt, 180);
    if (!freshness.valid) {
      return this.handleRejection({
        missionId: params.missionId,
        proofId: proof?.id,
        strategy: 'RULE_HEURISTIC',
        reason: `Proof capture is stale (${freshness.ageSeconds}s old). Live action within 3 minutes required.`,
        advice: 'Please capture evidence live when executing the mission.',
        metrics: { durationSec: freshness.ageSeconds }
      });
    }

    // B. Illumination Check (>= minLux)
    const minLux = taskRules.minLuminance || 25;
    const illum = AntiCheatValidator.validateIllumination(ambientLux, minLux);
    if (!illum.valid) {
      return this.handleRejection({
        missionId: params.missionId,
        proofId: proof?.id,
        strategy: 'RULE_HEURISTIC',
        reason: `Scene illumination too dark (${illum.lux} lux). Minimum required: ${minLux} lux.`,
        advice: 'Turn on room lighting or move to a well-lit area before capturing.',
        metrics: { illuminationLux: illum.lux }
      });
    }

    // C. Optical Entropy Check (>= 0.15)
    const entropy = AntiCheatValidator.validateOpticalEntropy(entropyScore, 0.15);
    if (!entropy.valid) {
      return this.handleRejection({
        missionId: params.missionId,
        proofId: proof?.id,
        strategy: 'RULE_HEURISTIC',
        reason: `Camera lens appears covered or obscured (optical entropy ${entropy.score.toFixed(2)}).`,
        advice: 'Uncover the camera lens and ensure clear visibility of your task.',
        metrics: { entropyScore: entropy.score }
      });
    }

    // D. Gallery Upload Check
    if (!AntiCheatValidator.validateLiveStream(isGallery)) {
      return this.handleRejection({
        missionId: params.missionId,
        proofId: proof?.id,
        strategy: 'RULE_HEURISTIC',
        reason: 'Gallery uploads are prohibited. Live camera capture required.',
        advice: 'Use the Habitat live viewfinder to capture proof in real-time.',
        metrics: {}
      });
    }

    // 3. Task-Specific Strategy Evaluation
    const isVideo = proof?.mediaType?.includes('video') || proof?.mimeType?.includes('video') || taskRow?.proof_type === 'VIDEO';

    // Strategy 1: Pose Estimation / Exercise Repetitions
    if (isVideo && (taskRules.minRepetitions || taskCategory === 'PHYSICAL')) {
      const requiredReps = taskRules.minRepetitions || 10;
      const detectedReps = params.telemetry?.motionCycles ?? proof?.deviceTelemetry?.motionCycles ?? (proof?.deviceTelemetry?.accelerometerMotion ? requiredReps : 0);
      const poseConf = params.telemetry?.poseConfidence ?? 0.92;

      const repResult = PoseRepCounter.evaluateRepetitions(detectedReps, requiredReps, poseConf);
      if (!repResult.passed) {
        return this.handleRejection({
          missionId: params.missionId,
          proofId: proof?.id,
          strategy: 'POSE_ESTIMATION_REPS',
          reason: repResult.rejectionReason!,
          advice: `Perform ${requiredReps} complete repetitions maintaining full range of motion.`,
          metrics: { repsCounted: detectedReps }
        });
      }

      return this.handleAcceptance({
        missionId: params.missionId,
        proofId: proof?.id,
        strategy: 'POSE_ESTIMATION_REPS',
        confidence: repResult.confidence,
        metrics: { repsCounted: detectedReps, illuminationLux: ambientLux }
      });
    }

    // Strategy 2: Smart Computer Vision & Object Recognition
    const requiredLabels: string[] = taskRules.requiredLabels || this.inferLabelsForTask(taskRow?.template_id || taskRow?.name || '');
    if (requiredLabels.length > 0) {
      const detectedLabels: string[] = params.telemetry?.detectedLabels ?? proof?.deviceTelemetry?.detectedLabels ?? [];
      const cvResult = CvLabelDetector.evaluateLabels(detectedLabels, requiredLabels, 0.70);

      if (!cvResult.matched && detectedLabels.length > 0) {
        return this.handleRejection({
          missionId: params.missionId,
          proofId: proof?.id,
          strategy: 'OBJECT_DETECTION_CV',
          reason: `Required target object not detected in frame (${cvResult.missingObjects.join(', ')}).`,
          advice: `Frame the ${cvResult.missingObjects[0]} clearly in the center of your camera viewport.`,
          metrics: { detectedObjects: detectedLabels }
        });
      }

      return this.handleAcceptance({
        missionId: params.missionId,
        proofId: proof?.id,
        strategy: 'OBJECT_DETECTION_CV',
        confidence: cvResult.confidence,
        metrics: { detectedObjects: cvResult.matchedObjects.length > 0 ? cvResult.matchedObjects : requiredLabels, illuminationLux: ambientLux }
      });
    }

    // Strategy 3: Rule Heuristic Verification (Default Pass)
    return this.handleAcceptance({
      missionId: params.missionId,
      proofId: proof?.id,
      strategy: 'RULE_HEURISTIC',
      confidence: 0.95,
      metrics: { illuminationLux: ambientLux }
    });
  }

  private static handleAcceptance(params: {
    missionId: string;
    proofId?: string;
    strategy: VerificationStrategy;
    confidence: number;
    metrics: any;
  }) {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    const reportId = uuidv4();

    // 1. Update Proof to ACCEPTED
    if (params.proofId) {
      db.prepare("UPDATE proofs SET verification_status = 'ACCEPTED', rejection_reason = NULL, updated_at = ? WHERE id = ?").run(
        now,
        params.proofId
      );
    }

    // 2. Complete Mission Atomically
    const completed = MissionsService.completeMission(params.missionId);

    // 3. Record Verification Report & Verification Entity
    db.prepare(`
      INSERT INTO verification_reports (
        id, mission_id, proof_id, strategy_used, is_valid, confidence_score, rejection_reason, extracted_metrics, created_at
      ) VALUES (?, ?, ?, ?, 1, ?, NULL, ?, ?)
    `).run(
      reportId,
      params.missionId,
      params.proofId || null,
      params.strategy,
      params.confidence,
      JSON.stringify(params.metrics || {}),
      now
    );

    db.prepare(`
      INSERT INTO verifications (
        id, proof_id, mission_id, attempt_id, user_id, status, decision, confidence,
        verifier, verifier_version, reasons, checks, started_at, completed_at, created_at
      ) VALUES (?, ?, ?, NULL, ?, 'COMPLETED', 'ACCEPT', ?, ?, 'v1.0', '[]', ?, ?, ?, ?)
    `).run(
      reportId,
      params.proofId || 'none',
      params.missionId,
      completed?.userId || 'default-user',
      params.confidence,
      params.strategy,
      JSON.stringify(params.metrics?.checks || []),
      now,
      now,
      now
    );

    // 4. Log Mission Verified Event
    db.prepare(`
      INSERT INTO mission_events (id, mission_id, type, from_status, to_status, metadata, created_at)
      VALUES (?, ?, 'MISSION_VERIFIED', 'VERIFYING', 'COMPLETED', ?, ?)
    `).run(
      uuidv4(),
      params.missionId,
      JSON.stringify({ strategy: params.strategy, confidence: params.confidence, metrics: params.metrics }),
      now
    );

    const task = db.prepare('SELECT base_xp FROM tasks WHERE id = ?').get(completed?.taskId) as any;

    return {
      isValid: true,
      strategyUsed: params.strategy,
      confidenceScore: params.confidence,
      rejectionReason: null,
      extractedMetrics: params.metrics,
      missionStatus: 'COMPLETED',
      xpAwarded: task?.base_xp || 50
    };
  }

  private static handleRejection(params: {
    missionId: string;
    proofId?: string;
    strategy: VerificationStrategy;
    reason: string;
    advice: string;
    metrics: any;
  }) {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    const reportId = uuidv4();
    const mission = MissionsService.getById(params.missionId);

    // 1. Update Proof to REJECTED
    if (params.proofId) {
      db.prepare("UPDATE proofs SET verification_status = 'REJECTED', rejection_reason = ?, updated_at = ? WHERE id = ?").run(
        params.reason,
        now,
        params.proofId
      );
    }

    // 2. Set Mission Status to ACTIVE for Retry Cycle
    db.prepare("UPDATE missions SET status = 'ACTIVE', updated_at = ? WHERE id = ?").run(now, params.missionId);

    // 3. Record Verification Report & Verification Entity
    db.prepare(`
      INSERT INTO verification_reports (
        id, mission_id, proof_id, strategy_used, is_valid, confidence_score, rejection_reason, extracted_metrics, created_at
      ) VALUES (?, ?, ?, ?, 0, 0.20, ?, ?, ?)
    `).run(
      reportId,
      params.missionId,
      params.proofId || null,
      params.strategy,
      params.reason,
      JSON.stringify(params.metrics || {}),
      now
    );

    db.prepare(`
      INSERT INTO verifications (
        id, proof_id, mission_id, attempt_id, user_id, status, decision, confidence,
        verifier, verifier_version, reasons, checks, started_at, completed_at, created_at
      ) VALUES (?, ?, ?, NULL, ?, 'COMPLETED', 'REJECT', 0.20, ?, 'v1.0', ?, '[]', ?, ?, ?)
    `).run(
      reportId,
      params.proofId || 'none',
      params.missionId,
      mission?.userId || 'default-user',
      params.strategy,
      JSON.stringify([params.reason]),
      now,
      now,
      now
    );

    // 4. Log Rejection Event
    db.prepare(`
      INSERT INTO mission_events (id, mission_id, type, from_status, to_status, metadata, created_at)
      VALUES (?, ?, 'MISSION_REJECTED', 'VERIFYING', 'ACTIVE', ?, ?)
    `).run(
      uuidv4(),
      params.missionId,
      JSON.stringify({ reason: params.reason, advice: params.advice }),
      now
    );

    return {
      isValid: false,
      strategyUsed: params.strategy,
      confidenceScore: 0.20,
      rejectionReason: params.reason,
      actionableAdvice: params.advice,
      extractedMetrics: params.metrics,
      missionStatus: 'ACTIVE',
      xpAwarded: 0
    };
  }

  /**
   * Retrieves latest verification report for a mission
   */
  public static getReport(missionId: string) {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM verification_reports WHERE mission_id = ? ORDER BY created_at DESC LIMIT 1').get(missionId) as any;
    if (!row) return null;

    return {
      id: row.id,
      missionId: row.mission_id,
      proofId: row.proof_id,
      strategyUsed: row.strategy_used,
      isValid: Boolean(row.is_valid),
      confidenceScore: row.confidence_score,
      rejectionReason: row.rejection_reason,
      extractedMetrics: JSON.parse(row.extracted_metrics || '{}'),
      createdAt: row.created_at
    };
  }

  private static inferLabelsForTask(identifier: string): string[] {
    const id = identifier.toLowerCase();
    if (id.includes('bed')) return ['bed', 'pillow', 'blanket'];
    if (id.includes('hydrate') || id.includes('water') || id.includes('glass')) return ['glass', 'cup', 'bottle', 'water'];
    if (id.includes('teeth') || id.includes('brush')) return ['toothbrush', 'sink', 'faucet'];
    if (id.includes('sunlight') || id.includes('outside')) return ['sky', 'sunlight', 'tree', 'outdoor'];
    if (id.includes('read') || id.includes('book')) return ['book', 'page', 'text'];
    return [];
  }
}
