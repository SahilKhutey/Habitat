// Pose Extraction Service: Extracts video/photo frames from storage and runs MoveNet pose estimation
import { IStorageProvider } from '../../storage/domain/storage-provider.interface';
import { StorageFactory } from '../../storage/storage.factory';
import { IVisionProvider, VisionFrame, VisionInput } from '../domain/vision-provider.interface';
import { VisionProviderFactory } from '../vision.factory';
import { IVideoFrameExtractor, FFmpegFrameExtractor } from '../infrastructure/video-frame-extractor';
import { FramePoseRecord, VerificationEvidence } from '../domain/evidence.types';
import { PoseGeometryCalculator } from '../engine/pose-geometry.calculator';
import { PushupStateMachine } from '../domain/pushup-state-machine';
import { LivenessAnalyzer } from '../engine/liveness-analyzer';

export interface PoseExtractionOptions {
  storageProvider?: IStorageProvider;
  visionProvider?: IVisionProvider;
  videoExtractor?: IVideoFrameExtractor;
}

export class PoseExtractionService {
  private readonly storageProvider: IStorageProvider;
  private readonly visionProvider: IVisionProvider;
  private readonly videoExtractor: IVideoFrameExtractor;

  constructor(options?: PoseExtractionOptions) {
    this.storageProvider = options?.storageProvider || StorageFactory.getProvider();
    this.visionProvider = options?.visionProvider || VisionProviderFactory.getProvider();
    this.videoExtractor = options?.videoExtractor || new FFmpegFrameExtractor();
  }

  /**
   * Reads raw media bytes from storage by objectKey, extracts 192x192 RGB frames,
   * executes MoveNet pose estimation, and computes trajectories & verification evidence.
   */
  public async extractPoseFromStorage(
    objectKey: string,
    context: {
      sessionId?: string;
      sessionNonce?: string;
      missionId?: string;
      taskSlug?: string;
      startedAt?: number;
      endedAt?: number;
    } = {}
  ): Promise<{
    evidence: VerificationEvidence;
    frames: VisionFrame[];
    frameTrajectory: FramePoseRecord[];
  }> {
    // 1. Fetch raw media bytes from storage
    const mediaBuffer = await this.storageProvider.getObjectBuffer(objectKey);

    // 2. Extract 192x192 RGB24 frames from media buffer
    const extractedFrames = await this.videoExtractor.extract(mediaBuffer, {
      maxFrames: 60,
      fps: 5
    });

    const frames: VisionFrame[] = extractedFrames.map((f) => ({
      timestampMs: f.timestampMs,
      frameIndex: f.frameIndex,
      frameHash: f.frameHash,
      width: 192,
      height: 192,
      data: f.imageBuffer || new Uint8Array(192 * 192 * 3)
    }));

    const sessionId = context.sessionId || `session_${Date.now()}`;
    const sessionNonce = context.sessionNonce || `nonce_${sessionId}`;
    const taskSlug = context.taskSlug || 'pushups';
    const startedAt = context.startedAt || Date.now() - frames.length * 200;
    const endedAt = context.endedAt || Date.now();

    const visionInput: VisionInput = {
      sessionId,
      taskSlug,
      frames,
      startedAt,
      endedAt
    };

    // 3. Execute vision provider pose detection or end-to-end evidence generation
    let evidence: VerificationEvidence;
    let frameTrajectory: FramePoseRecord[] = [];

    if (typeof (this.visionProvider as any).generateVerificationEvidence === 'function') {
      evidence = await (this.visionProvider as any).generateVerificationEvidence(visionInput, sessionNonce);
      frameTrajectory = evidence.pose.frameTrajectory;
    } else {
      const poseResult = await this.visionProvider.detectPose(visionInput);

      for (const detection of poseResult.detections) {
        const geometry = PoseGeometryCalculator.calculateMetrics(detection.keypoints);
        frameTrajectory.push({
          timestampMs: detection.timestampMs,
          frameIndex: detection.frameIndex,
          frameHash: detection.frameHash,
          keypoints: detection.keypoints,
          leftElbowAngleDeg: geometry.leftElbowAngleDeg,
          rightElbowAngleDeg: geometry.rightElbowAngleDeg,
          bodyAlignmentAngleDeg: geometry.bodyAlignmentAngleDeg
        });
      }

      const sm = new PushupStateMachine();
      const repStats = sm.feedTrajectory(frameTrajectory);
      const livenessResult = LivenessAnalyzer.analyze(frameTrajectory);

      evidence = {
        sessionId,
        sessionNonce,
        missionId: context.missionId || `mission_${sessionId}`,
        taskSlug,
        startedAt: new Date(startedAt).toISOString(),
        completedAt: new Date(endedAt).toISOString(),
        durationMs: endedAt - startedAt,
        pose: {
          model: this.visionProvider.modelName,
          modelVersion: this.visionProvider.modelVersion,
          totalFramesSampled: frames.length,
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
          evidencePayloadHash: `sha256_${sessionId}_${frameTrajectory.length}`
        }
      };
    }

    return {
      evidence,
      frames,
      frameTrajectory
    };
  }
}
