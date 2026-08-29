// Proof Asset Entity & Domain Repository Contract
import { IRepository } from './repository.interface';

export interface ProofAssetEntity {
  id: string;
  missionId: string;
  userId: string;
  attemptId?: string | null;
  uploadId?: string | null;
  mediaType: 'PHOTO' | 'VIDEO';
  storageKey: string;
  objectKey: string;
  thumbnailKey?: string | null;
  mimeType: string;
  sizeBytes: number;
  sha256?: string | null;
  durationMs?: number | null;
  width?: number | null;
  height?: number | null;
  capturedAt: string;
  uploadedAt?: string | null;
  verifiedAt?: string | null;
  verificationStatus: 'PENDING' | 'ACCEPTED' | 'REJECTED' | 'REVIEW';
  rejectionReason?: string | null;
  deviceTelemetry: Record<string, any>;
  createdAt: string;
  updatedAt?: string | null;
}

export interface IProofRepository extends IRepository<ProofAssetEntity> {
  findByMissionId(missionId: string): Promise<ProofAssetEntity[]> | ProofAssetEntity[];
  findByUploadId(uploadId: string): Promise<ProofAssetEntity | null> | (ProofAssetEntity | null);
  updateVerification(id: string, status: 'ACCEPTED' | 'REJECTED' | 'REVIEW', reason?: string | null): Promise<void> | void;
  markUploadComplete(id: string, sizeBytes: number, sha256: string): Promise<void> | void;
}
