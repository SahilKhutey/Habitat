// Production Proof Capture Service managing camera capture sessions and proof finalization
import { v4 as uuidv4 } from 'uuid';
import { ProofFileStore, ProofFileMetadata } from './proof-file-store';
import { DatabaseFactory } from '../../../db/database.factory';
import { IProofRepository } from '../../../repositories/interfaces/proof.repository.interface';
import { MissionService } from '../../missions/domain/mission.service';

export interface ProofCaptureSession {
  sessionId: string;
  missionId: string;
  userId: string;
  createdAt: string;
  payload?: Buffer;
  mimeType?: string;
}

export interface FinalizedProof {
  id: string;
  missionId: string;
  userId: string;
  storageKey: string;
  sha256: string;
  fileSizeBytes: number;
  mimeType: string;
  createdAt: string;
}

export class ProofCaptureService {
  private static activeSessions = new Map<string, ProofCaptureSession>();
  private readonly proofRepo: IProofRepository;
  private readonly missionService: MissionService;

  constructor(proofRepo?: IProofRepository, missionService?: MissionService) {
    this.proofRepo = proofRepo || DatabaseFactory.getProofRepository();
    this.missionService = missionService || new MissionService();
  }

  public initializeSession(missionId: string, userId: string): ProofCaptureSession {
    const sessionId = uuidv4();
    const session: ProofCaptureSession = {
      sessionId,
      missionId,
      userId,
      createdAt: new Date().toISOString()
    };
    ProofCaptureService.activeSessions.set(sessionId, session);
    return session;
  }

  public capturePayload(sessionId: string, bytes: Buffer, mimeType: string): void {
    const session = ProofCaptureService.activeSessions.get(sessionId);
    if (!session) {
      throw new Error(`SESSION_NOT_FOUND: Capture session ${sessionId} does not exist.`);
    }

    if (!bytes || bytes.length === 0) {
      throw new Error('INVALID_PAYLOAD: Captured proof bytes cannot be empty.');
    }

    session.payload = bytes;
    session.mimeType = mimeType;
  }

  public async finalizeProof(sessionId: string): Promise<FinalizedProof> {
    const session = ProofCaptureService.activeSessions.get(sessionId);
    if (!session || !session.payload) {
      throw new Error(`INVALID_SESSION: No payload recorded for capture session ${sessionId}.`);
    }

    const proofId = uuidv4();
    const ext = session.mimeType?.includes('video') ? 'mp4' : 'jpg';

    // 1. Save to physical proof storage and compute SHA-256
    const metadata: ProofFileMetadata = await ProofFileStore.saveProof({
      missionId: session.missionId,
      proofId,
      bytes: session.payload,
      extension: ext,
      mimeType: session.mimeType
    });

    // 2. Persist proof entity in database
    const mediaType = session.mimeType?.includes('video') ? 'VIDEO' : 'PHOTO';

    await this.proofRepo.create({
      id: proofId,
      userId: session.userId,
      missionId: session.missionId,
      mediaType,
      storageKey: metadata.storageKey,
      objectKey: metadata.storageKey,
      mimeType: metadata.mimeType,
      sizeBytes: metadata.fileSizeBytes,
      sha256: metadata.sha256,
      capturedAt: metadata.createdAt,
      createdAt: metadata.createdAt,
      verificationStatus: 'PENDING',
      deviceTelemetry: {}
    });

    // 3. Advance mission to SUBMITTED / VERIFYING
    await this.missionService.submitProof(session.missionId, proofId);

    // 4. Remove session from memory
    ProofCaptureService.activeSessions.delete(sessionId);

    return {
      id: proofId,
      missionId: session.missionId,
      userId: session.userId,
      storageKey: metadata.storageKey,
      sha256: metadata.sha256,
      fileSizeBytes: metadata.fileSizeBytes,
      mimeType: metadata.mimeType,
      createdAt: metadata.createdAt
    };
  }

  public discardProof(sessionId: string): void {
    ProofCaptureService.activeSessions.delete(sessionId);
  }
}
