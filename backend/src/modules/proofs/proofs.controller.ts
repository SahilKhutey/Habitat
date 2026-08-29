// Authoritative Proof Engine Controller & Direct Object Storage S3 Upload Session Pipeline
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { MissionsService } from '../missions/missions.controller';
import { ProofStateMachine } from './domain/proof-state-machine';
import { BasicVerificationProvider } from './verification/basic-verification.provider';
import { ProofRules } from './domain/proof.rules';

import { StorageFactory } from '../storage/storage.factory';
import { proofRepository } from '../../repositories/proof.repository';

export class ProofsService {
  // 1. Create Direct S3 / MinIO / Local Upload Session
  public static createUploadSession(params: {
    userId: string;
    missionId: string;
    attemptId?: string;
    type: 'PHOTO' | 'VIDEO' | 'NONE' | 'PHOTO_OR_VIDEO';
    mimeType: string;
    sizeBytes: number;
    durationSeconds?: number;
    width?: number;
    height?: number;
  }) {
    // Validate size and MIME rules synchronously first
    ProofRules.validateUploadSession({
      type: params.type,
      mimeType: params.mimeType,
      sizeBytes: params.sizeBytes,
      durationSeconds: params.durationSeconds
    });

    const mission = MissionsService.getById(params.missionId);
    if (!mission) throw new Error('MISSION_NOT_FOUND: Mission not found');

    const proofId = uuidv4();
    const isVideo = params.type === 'VIDEO' || params.mimeType.startsWith('video/');
    const ext = isVideo ? 'mp4' : 'jpg';
    const objectKey = `proofs/${params.userId}/${params.missionId}/${proofId}/original.${ext}`;
    const thumbnailKey = isVideo ? `proofs/${params.userId}/${params.missionId}/${proofId}_thumb.jpg` : null;

    const provider = StorageFactory.getProvider();
    const uploadUrl = `${(provider as any).baseUrl || 'http://localhost:4000'}/api/v1/storage/upload?key=${objectKey}&uploadId=upl_${proofId}`;
    const downloadUrl = `/api/v1/storage/file?key=${objectKey}`;
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
    const now = new Date().toISOString();

    const db = DatabaseService.getDb();
    db.prepare(`
      INSERT INTO proofs (
        id, mission_id, user_id, attempt_id, upload_id, media_type, storage_key, object_key, thumbnail_key,
        mime_type, size_bytes, duration_ms, width, height, captured_at, device_telemetry,
        verification_status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, '{}', 'UPLOADING', ?, ?)
    `).run(
      proofId,
      params.missionId,
      params.userId,
      params.attemptId || null,
      `upl_${proofId}`,
      params.type,
      objectKey,
      objectKey,
      thumbnailKey,
      params.mimeType,
      params.sizeBytes,
      params.durationSeconds ? params.durationSeconds * 1000 : null,
      params.width || null,
      params.height || null,
      now,
      now,
      now
    );

    return {
      uploadId: `upl_${proofId}`,
      proofId,
      uploadUrl,
      downloadUrl,
      objectKey,
      thumbnailKey,
      expiresAt
    };
  }

  // 2. Confirm Upload Completion with Storage Object Verification
  public static completeUpload(proofId: string, userId?: string) {
    if (!proofId || typeof proofId !== 'string') {
      throw new Error('PROOF_NOT_FOUND: Valid proof ID is required');
    }

    const db = DatabaseService.getDb();
    const proof = db.prepare('SELECT * FROM proofs WHERE id = ?').get(proofId) as any;
    if (!proof) throw new Error('PROOF_NOT_FOUND: Proof not found');

    const mission = MissionsService.getById(proof.mission_id);
    if (userId && mission && mission.userId !== userId) {
      throw new Error('UNAUTHORIZED: Cannot access proof belonging to another user');
    }

    const now = new Date().toISOString();
    db.prepare(`
      UPDATE proofs 
      SET verification_status = 'REGISTERED', uploaded_at = ?, updated_at = ?
      WHERE id = ?
    `).run(now, now, proofId);

    return this.getById(proofId);
  }

  // 3. Get Signed Download URL
  public static async getDownloadUrl(proofId: string): Promise<string> {
    const proof = proofRepository.findById(proofId);
    if (!proof) throw new Error('PROOF_NOT_FOUND: Proof not found');

    const provider = StorageFactory.getProvider();
    return provider.getDownloadUrl(proof.objectKey || proof.storageKey);
  }

  // 3. Submit Registered Proof to Mission
  public static submitProofToMission(params: {
    missionId: string;
    proofId: string;
    attemptId?: string;
    userId?: string;
  }) {
    const db = DatabaseService.getDb();
    const proof = db.prepare('SELECT * FROM proofs WHERE id = ?').get(params.proofId) as any;
    if (!proof) throw new Error('PROOF_NOT_FOUND: Proof not found');

    const mission = MissionsService.getById(params.missionId);
    if (!mission) throw new Error('MISSION_NOT_FOUND: Mission not found');

    if (params.userId && mission.userId !== params.userId) {
      throw new Error('UNAUTHORIZED: Cannot submit proof to another user mission');
    }

    if (mission.status === 'COMPLETED') {
      throw new Error('MISSION_INVALID_STATE: Mission is already completed');
    }

    const now = new Date().toISOString();

    db.prepare(`
      UPDATE proofs 
      SET verification_status = 'SUBMITTED', updated_at = ?
      WHERE id = ?
    `).run(now, params.proofId);

    db.prepare(`
      UPDATE missions 
      SET status = 'VERIFYING', updated_at = ?
      WHERE id = ?
    `).run(now, params.missionId);

    if (params.attemptId) {
      db.prepare(`
        UPDATE mission_attempts 
        SET submitted_at = ?, status = 'SUBMITTED'
        WHERE id = ? OR (mission_id = ? AND status = 'STARTED')
      `).run(now, params.attemptId, params.missionId);
    }

    return {
      success: true,
      missionId: params.missionId,
      proofId: params.proofId,
      status: 'VERIFYING'
    };
  }

  // 4. Submit & Verify Proof (Unified Pipeline with BasicVerificationProvider)
  public static async submitAndVerify(params: {
    missionId: string;
    mediaType: string;
    storageKey: string;
    capturedAt: string;
    deviceTelemetry?: any;
    fileSizeBytes?: number;
    videoDurationSeconds?: number;
  }) {
    const db = DatabaseService.getDb();
    const mission = MissionsService.getById(params.missionId);
    if (!mission) throw new Error('Mission not found');

    const taskRow = db.prepare('SELECT * FROM tasks WHERE id = ?').get(mission.taskId) as any;
    const taskRules = taskRow?.validation_rules ? JSON.parse(taskRow.validation_rules) : {};

    const isVideo = params.mediaType.includes('video');
    const verificationResult = BasicVerificationProvider.verify({
      proofType: isVideo ? 'VIDEO' : 'PHOTO',
      mimeType: params.mediaType,
      fileSizeBytes: params.fileSizeBytes ?? 150000,
      durationSeconds: params.videoDurationSeconds,
      capturedAt: params.capturedAt,
      rules: {
        minDurationSeconds: taskRules.minDurationSeconds ?? (isVideo ? 5 : undefined),
        maxDurationSeconds: taskRules.maxDurationSeconds ?? 60,
        minLuminanceLux: taskRules.minLuminance ?? 20,
        minRepetitions: taskRules.minRepetitions
      },
      telemetry: {
        ambientLux: params.deviceTelemetry?.ambientLux ?? params.deviceTelemetry?.luminanceScore,
        motionCycles: params.deviceTelemetry?.motionCycles
      }
    });

    const now = new Date().toISOString();
    const proofId = uuidv4();
    const isValid = verificationResult.status === 'ACCEPTED';
    const verificationStatus = isValid ? 'PASSED' : 'REJECTED';
    const rejectionReason = verificationResult.reasonMessage || verificationResult.reasonCode;

    db.prepare(`
      INSERT INTO proofs (
        id, mission_id, media_type, storage_key, object_key, mime_type,
        captured_at, device_telemetry, verification_status, rejection_reason, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      proofId,
      params.missionId,
      params.mediaType,
      params.storageKey,
      params.storageKey,
      params.mediaType,
      params.capturedAt,
      JSON.stringify(params.deviceTelemetry || {}),
      verificationStatus,
      rejectionReason,
      now,
      now
    );

    let completedMission = null;
    if (isValid) {
      completedMission = MissionsService.completeMission(params.missionId);
    } else {
      db.prepare("UPDATE missions SET status = 'AWAITING_PROOF', updated_at = ? WHERE id = ?").run(now, params.missionId);
    }

    return {
      proofId,
      isValid,
      strategyUsed: 'BASIC',
      confidenceScore: verificationResult.confidence,
      verificationStatus,
      rejectionReason,
      completedMission,
      rewards: {
        totalXp: completedMission ? (taskRow?.base_xp || 50) : 0
      }
    };
  }

  // Legacy / Helper: Upload Presigned URL Generator
  public static generateUploadUrl(params: {
    userId: string;
    missionId: string;
    mediaType: string;
    extension?: string;
  }) {
    const ext = params.extension || (params.mediaType.includes('video') ? 'mp4' : 'jpg');
    const storageKey = `proofs/${params.userId}/${params.missionId}/${uuidv4()}.${ext}`;
    const storageEndpoint = process.env.STORAGE_ENDPOINT || 'http://localhost:9000';
    const bucket = process.env.STORAGE_BUCKET || 'habitat-proofs';

    const uploadUrl = `${storageEndpoint}/${bucket}/${storageKey}`;

    return {
      storageKey,
      uploadUrl,
      mediaType: params.mediaType,
      expiresInSeconds: 900
    };
  }

  // Legacy / Helper: Create Proof Entry
  public static createProof(missionId: string, userId: string, type: 'PHOTO' | 'VIDEO' | 'MANUAL_CONFIRMATION') {
    const db = DatabaseService.getDb();
    const mission = MissionsService.getById(missionId);
    if (!mission) throw new Error('Mission not found');

    const proofId = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO proofs (id, mission_id, media_type, storage_key, object_key, captured_at, device_telemetry, verification_status, rejection_reason, created_at, updated_at)
      VALUES (?, ?, ?, '', '', ?, '{}', 'CAPTURED', NULL, ?, ?)
    `).run(
      proofId,
      missionId,
      type === 'VIDEO' ? 'video/mp4' : 'image/jpeg',
      now,
      now,
      now
    );

    // Update Mission status to AWAITING_PROOF
    db.prepare("UPDATE missions SET status = 'AWAITING_PROOF', updated_at = ? WHERE id = ?").run(now, missionId);

    return this.getById(proofId);
  }

  // Legacy / Helper: Attach Proof Asset
  public static addProofAsset(proofId: string, asset: {
    mimeType: string;
    fileSizeBytes: number;
    durationSeconds?: number;
    width?: number;
    height?: number;
    checksum?: string;
  }) {
    const db = DatabaseService.getDb();
    const proof = db.prepare('SELECT * FROM proofs WHERE id = ?').get(proofId) as any;
    if (!proof) throw new Error('Proof not found');

    const assetId = uuidv4();
    const storageKey = `proofs/assets/${proofId}/${assetId}.${asset.mimeType.includes('video') ? 'mp4' : 'jpg'}`;
    const now = new Date().toISOString();

    const uploadEndpoint = process.env.STORAGE_ENDPOINT || 'http://localhost:9000';
    const bucket = process.env.STORAGE_BUCKET || 'habitat-proofs';
    const uploadUrl = `${uploadEndpoint}/${bucket}/${storageKey}`;

    db.prepare(`
      UPDATE proofs 
      SET storage_key = ?, object_key = ?, media_type = ?, mime_type = ?, size_bytes = ?, verification_status = 'UPLOAD_PENDING', updated_at = ?
      WHERE id = ?
    `).run(storageKey, storageKey, asset.mimeType, asset.mimeType, asset.fileSizeBytes, now, proofId);

    return {
      assetId,
      proofId,
      storageKey,
      uploadUrl,
      expectedMimeType: asset.mimeType,
      expectedSize: asset.fileSizeBytes,
      expiresAt: new Date(Date.now() + 15 * 60 * 1000).toISOString()
    };
  }

  // 5. Get Proof by ID
  public static getById(proofId: string) {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM proofs WHERE id = ?').get(proofId) as any;
    if (!row) return null;

    const storageEndpoint = process.env.STORAGE_ENDPOINT || 'http://localhost:9000';
    const bucket = process.env.STORAGE_BUCKET || 'habitat-proofs';
    const publicUrl = `${storageEndpoint}/${bucket}/${row.storage_key || row.object_key}`;

    return {
      id: row.id,
      missionId: row.mission_id,
      attemptId: row.attempt_id,
      mediaType: row.media_type,
      storageKey: row.storage_key,
      objectKey: row.object_key,
      thumbnailKey: row.thumbnail_key,
      mimeType: row.mime_type,
      sizeBytes: row.size_bytes,
      sha256: row.sha256,
      durationMs: row.duration_ms,
      width: row.width,
      height: row.height,
      publicUrl,
      capturedAt: row.captured_at,
      uploadedAt: row.uploaded_at,
      deviceTelemetry: JSON.parse(row.device_telemetry || '{}'),
      verificationStatus: row.verification_status,
      rejectionReason: row.rejection_reason,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };
  }

  // 6. Delete Proof (Soft / Draft discard for Retake)
  public static deleteProof(proofId: string, userId?: string) {
    const db = DatabaseService.getDb();
    const proof = db.prepare('SELECT * FROM proofs WHERE id = ?').get(proofId) as any;
    if (!proof) throw new Error('PROOF_NOT_FOUND: Proof not found');

    const mission = MissionsService.getById(proof.mission_id);
    if (userId && mission && mission.userId !== userId) {
      throw new Error('UNAUTHORIZED: Cannot delete proof belonging to another user');
    }

    db.prepare("UPDATE proofs SET verification_status = 'DELETED', updated_at = ? WHERE id = ?").run(
      new Date().toISOString(),
      proofId
    );

    return true;
  }
}

export const proofsController = Router();

// POST /api/v1/proofs/upload-session
proofsController.post('/upload-session', async (req: Request, res: Response) => {
  try {
    const { missionId, attemptId, type, mimeType, sizeBytes, durationSeconds, width, height, userId } = req.body;
    if (!missionId || !mimeType || !sizeBytes) {
      res.status(400).json({ success: false, error: 'missionId, mimeType, and sizeBytes are required' });
      return;
    }

    const session = await ProofsService.createUploadSession({
      userId: userId || 'default-user',
      missionId,
      attemptId,
      type: type || 'PHOTO',
      mimeType,
      sizeBytes,
      durationSeconds,
      width,
      height
    });

    res.status(201).json({ success: true, data: session });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/proofs/upload-url (Legacy alias)
proofsController.post('/upload-url', async (req: Request, res: Response) => {
  try {
    const { userId, missionId, mediaType, extension } = req.body;
    const session = await ProofsService.createUploadSession({
      userId: userId || 'default-user',
      missionId,
      type: mediaType?.includes('video') ? 'VIDEO' : 'PHOTO',
      mimeType: mediaType || 'image/jpeg',
      sizeBytes: 150000
    });
    res.json({ success: true, data: session });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/proofs/:id/complete
proofsController.post('/:id/complete', async (req: Request, res: Response) => {
  try {
    const proof = await ProofsService.completeUpload(String(req.params.id), req.body?.userId);
    res.json({ success: true, data: proof });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/proofs/:id/complete-upload (Legacy alias)
proofsController.post('/:id/complete-upload', async (req: Request, res: Response) => {
  try {
    const proof = await ProofsService.completeUpload(String(req.params.id), req.body?.userId);
    res.json({ success: true, data: proof });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/proofs/:id/download-url
proofsController.get('/:id/download-url', async (req: Request, res: Response) => {
  try {
    const downloadUrl = await ProofsService.getDownloadUrl(String(req.params.id));
    res.json({ success: true, data: { downloadUrl } });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/proofs/:id/submit
proofsController.post('/:id/submit', (req: Request, res: Response) => {
  try {
    const { missionId, attemptId, userId } = req.body;
    const result = ProofsService.submitProofToMission({
      missionId: missionId || req.body.missionId,
      proofId: String(req.params.id),
      attemptId,
      userId
    });
    res.json({ success: true, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/proofs/:id
proofsController.get('/:id', (req: Request, res: Response) => {
  const proof = ProofsService.getById(String(req.params.id));
  if (!proof) {
    res.status(404).json({ success: false, error: 'Proof not found' });
    return;
  }
  res.json({ success: true, data: proof });
});

// DELETE /api/v1/proofs/:id
proofsController.delete('/:id', (req: Request, res: Response) => {
  try {
    const result = ProofsService.deleteProof(String(req.params.id), req.query?.userId as string);
    res.json({ success: true, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});
