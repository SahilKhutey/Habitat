// Proof Verification & Ingestion Service
import { ProofRepository } from '../db/repositories/proofRepository';
import { TaskRepository } from '../db/repositories/taskRepository';
import { AntiCheatValidator, VerificationResult } from '../domain/antiCheat';
import { ProofAsset } from '../domain/types';

export interface SubmitProofDTO {
  missionId: string;
  mediaType: 'image/jpeg' | 'video/mp4';
  storageUrl: string;
  thumbnailUrl?: string;
  capturedAt: string;
  deviceMetadata: {
    ambientLux?: number;
    accelerometerMotion?: boolean;
    appVersion?: string;
    clientTimestamp?: number;
  };
}

export class VerificationService {
  /**
   * Evaluates proof, applies heuristics, and records asset in database
   */
  public static async verifyProof(
    taskId: string,
    dto: SubmitProofDTO
  ): Promise<{ proof: ProofAsset; result: VerificationResult }> {
    const task = TaskRepository.getById(taskId);
    if (!task) {
      throw new Error(`Task with ID ${taskId} not found for verification.`);
    }

    // 1. Run Anti-Cheat & Heuristic Checks
    const result = AntiCheatValidator.validateProof(
      {
        capturedAt: dto.capturedAt,
        mediaType: dto.mediaType,
        deviceMetadata: dto.deviceMetadata
      },
      task
    );

    // 2. Persist Proof Record in Database
    const proof = ProofRepository.create({
      missionId: dto.missionId,
      mediaType: dto.mediaType,
      storageUrl: dto.storageUrl,
      thumbnailUrl: dto.thumbnailUrl ?? null,
      capturedAt: dto.capturedAt,
      deviceMetadata: dto.deviceMetadata,
      verificationStatus: result.isValid ? 'ACCEPTED' : 'REJECTED',
      aiConfidenceScore: result.confidenceScore,
      rejectionReason: result.rejectionReason ?? undefined
    });

    return { proof, result };
  }
}
