// Authoritative Proof Validator Boundary
import { DatabaseService } from '../../../db/connection';
import { ProofFileStore } from '../../proofs/domain/proof-file-store';
import { ProofAssetEntity } from '../../../repositories/interfaces/proof.repository.interface';

export interface ValidationSuccess {
  isValid: true;
  proof: ProofAssetEntity;
  bytes: Buffer;
  mimeType: string;
}

export interface ValidationFailure {
  isValid: false;
  reason: string;
  code:
    | 'PROOF_NOT_FOUND'
    | 'UNAUTHORIZED_ACCESS'
    | 'MISSION_MISMATCH'
    | 'FILE_NOT_FOUND'
    | 'UNSUPPORTED_MIME_TYPE'
    | 'CORRUPTED_OR_EMPTY'
    | 'CHECKSUM_MISMATCH'
    | 'ALREADY_CONSUMED';
}

export type ProofValidationResult = ValidationSuccess | ValidationFailure;

export const SUPPORTED_MIME_TYPES = new Set([
  'video/mp4',
  'video/webm',
  'video/quicktime',
  'image/jpeg',
  'image/jpg',
  'image/png'
]);

export const MAX_FILE_SIZE_BYTES = 50 * 1024 * 1024; // 50 MB
export const MIN_FILE_SIZE_BYTES = 10; // 10 bytes minimum

export class ProofValidator {
  /**
   * Strictly validates evidence before passing into ML pipelines
   */
  public static async validate(params: {
    proofId: string;
    missionId: string;
    userId: string;
  }): Promise<ProofValidationResult> {
    const db = DatabaseService.getDb();

    // 1. Fetch proof entity from database
    const row = db.prepare('SELECT * FROM proofs WHERE id = ?').get(params.proofId) as any;
    if (!row) {
      return {
        isValid: false,
        reason: `Proof with ID "${params.proofId}" was not found in the evidence repository.`,
        code: 'PROOF_NOT_FOUND'
      };
    }

    // 2. Ownership & Mission Relationship Verification (Anti-IDOR)
    if (row.user_id !== params.userId) {
      return {
        isValid: false,
        reason: `Unauthorized: User "${params.userId}" does not own proof "${params.proofId}".`,
        code: 'UNAUTHORIZED_ACCESS'
      };
    }

    if (row.mission_id !== params.missionId) {
      return {
        isValid: false,
        reason: `Proof "${params.proofId}" belongs to mission "${row.mission_id}", not target mission "${params.missionId}".`,
        code: 'MISSION_MISMATCH'
      };
    }

    // 3. Prevent Replay of Already Accepted Proofs
    if (row.verification_status === 'ACCEPTED') {
      return {
        isValid: false,
        reason: `Proof "${params.proofId}" has already been verified and consumed.`,
        code: 'ALREADY_CONSUMED'
      };
    }

    // 4. File Storage Existence Check
    const storageKey = row.storage_key || row.object_key;
    if (!storageKey || !ProofFileStore.exists(storageKey)) {
      return {
        isValid: false,
        reason: `Proof media file is missing from private storage: ${storageKey}`,
        code: 'FILE_NOT_FOUND'
      };
    }

    // 5. Read Media Bytes and Verify Dimensions / Size
    let bytes: Buffer;
    try {
      bytes = ProofFileStore.readProof(storageKey);
    } catch (err: any) {
      return {
        isValid: false,
        reason: `Failed to read proof media from storage: ${err.message}`,
        code: 'CORRUPTED_OR_EMPTY'
      };
    }

    if (!bytes || bytes.length < MIN_FILE_SIZE_BYTES) {
      return {
        isValid: false,
        reason: `Proof file is empty or corrupted (size: ${bytes?.length ?? 0} bytes).`,
        code: 'CORRUPTED_OR_EMPTY'
      };
    }

    if (bytes.length > MAX_FILE_SIZE_BYTES) {
      return {
        isValid: false,
        reason: `Proof file exceeds maximum size limit of ${MAX_FILE_SIZE_BYTES} bytes.`,
        code: 'CORRUPTED_OR_EMPTY'
      };
    }

    // 6. MIME Type Validation
    const mimeType = (row.mime_type || 'application/octet-stream').toLowerCase();
    if (!SUPPORTED_MIME_TYPES.has(mimeType)) {
      return {
        isValid: false,
        reason: `Unsupported media MIME type: "${mimeType}". Supported types: ${Array.from(SUPPORTED_MIME_TYPES).join(', ')}`,
        code: 'UNSUPPORTED_MIME_TYPE'
      };
    }

    // 7. Cryptographic Checksum Verification (SHA-256)
    const computedSha = ProofFileStore.computeSha256(bytes);
    if (row.sha256 && row.sha256 !== computedSha) {
      return {
        isValid: false,
        reason: `Tampering detected: Computed SHA-256 (${computedSha}) does not match recorded hash (${row.sha256}).`,
        code: 'CHECKSUM_MISMATCH'
      };
    }

    const proof: ProofAssetEntity = {
      id: row.id,
      missionId: row.mission_id,
      userId: row.user_id,
      attemptId: row.attempt_id,
      uploadId: row.upload_id,
      mediaType: row.media_type || (mimeType.includes('video') ? 'VIDEO' : 'PHOTO'),
      storageKey: row.storage_key,
      objectKey: row.object_key,
      thumbnailKey: row.thumbnail_key,
      mimeType: row.mime_type,
      sizeBytes: bytes.length,
      sha256: computedSha,
      capturedAt: row.captured_at || row.created_at,
      uploadedAt: row.uploaded_at,
      verifiedAt: row.verified_at,
      verificationStatus: row.verification_status || 'PENDING',
      rejectionReason: row.rejection_reason,
      deviceTelemetry: JSON.parse(row.device_telemetry || '{}'),
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };

    return {
      isValid: true,
      proof,
      bytes,
      mimeType
    };
  }
}
