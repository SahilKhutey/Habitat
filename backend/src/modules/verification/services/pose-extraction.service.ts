// Pose Extraction Service: Reads proof media from storage and runs the canonical vision pipeline
// This service's ONE unique responsibility: storage retrieval + frame decoding.
// All pose inference, geometry, state machine, and liveness logic is delegated
// to TfjsVisionProvider.generateVerificationEvidence() — the single authoritative pipeline.
import { IStorageProvider } from '../../storage/domain/storage-provider.interface';
import { StorageFactory } from '../../storage/storage.factory';
import { IVisionProvider, VisionFrame, VisionInput } from '../domain/vision-provider.interface';
import { VisionProviderFactory } from '../vision.factory';
import { IVideoFrameExtractor, FFmpegFrameExtractor } from '../infrastructure/video-frame-extractor';
import { FramePoseRecord, VerificationEvidence } from '../domain/evidence.types';

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
   * Reads raw media bytes from storage by objectKey, decodes frames,
   * and delegates to the vision provider's generateVerificationEvidence pipeline
   * for authoritative server-side pose inference, geometry, repetition counting, and liveness.
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

    // 2. Decode into 192×192 RGB frames — image via direct pass-through, video via FFmpeg demux
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

    // 3. Delegate pose inference → geometry → state machine → liveness → evidence assembly
    // to the canonical vision provider pipeline. All providers returned by VisionProviderFactory
    // implement generateVerificationEvidence (enforced at factory level).
    const providerWithEvidence = this.visionProvider as any;
    if (typeof providerWithEvidence.generateVerificationEvidence !== 'function') {
      throw new Error(
        `Vision provider "${this.visionProvider.providerId}" does not implement generateVerificationEvidence. ` +
        `Use VISION_PROVIDER=tfjs, movenet, or tflite.`
      );
    }

    const evidence: VerificationEvidence = await providerWithEvidence.generateVerificationEvidence(
      visionInput,
      sessionNonce
    );

    // Override missionId from context if provided
    if (context.missionId) {
      (evidence as any).missionId = context.missionId;
    }

    return {
      evidence,
      frames,
      frameTrajectory: evidence.pose.frameTrajectory
    };
  }
}
