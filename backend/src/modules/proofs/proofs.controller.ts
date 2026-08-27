// Authoritative Proof Engine Controller & Verification Pipeline
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { MissionsService } from '../missions/missions.controller';
import { VerificationEngine } from '../verification/verification.engine';
import { ProofStateMachine } from './domain/proof-state-machine';
import { BasicVerificationProvider } from './verification/basic-verification.provider';
import { ProofStatus } from './domain/proof.types';

export class ProofsService {
  // 1. Upload Presigned URL Generator
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

  // 2. Create Proof Entry
  public static createProof(missionId: string, userId: string, type: 'PHOTO' | 'VIDEO' | 'MANUAL_CONFIRMATION') {
    const db = DatabaseService.getDb();
    const mission = MissionsService.getById(missionId);
    if (!mission) throw new Error('Mission not found');

    const proofId = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO proofs (id, mission_id, media_type, storage_key, captured_at, device_telemetry, verification_status, rejection_reason, created_at)
      VALUES (?, ?, ?, '', ?, '{}', 'CAPTURED', NULL, ?)
    `).run(
      proofId,
      missionId,
      type === 'VIDEO' ? 'video/mp4' : 'image/jpeg',
      now,
      now
    );

    // Update Mission status to AWAITING_PROOF
    db.prepare("UPDATE missions SET status = 'AWAITING_PROOF', updated_at = ? WHERE id = ?").run(now, missionId);

    return this.getById(proofId);
  }

  // 3. Attach Proof Asset
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
      SET storage_key = ?, media_type = ?, verification_status = 'UPLOAD_PENDING', updated_at = ?
      WHERE id = ?
    `).run(storageKey, asset.mimeType, now, proofId);

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

  // 4. Submit Proof for Verification
  public static async submitAndVerify(params: {
    missionId: string;
    mediaType: string;
    storageKey: string;
    capturedAt: string;
    deviceTelemetry?: {
      ambientLux?: number;
      accelerometerMotion?: boolean;
      durationSeconds?: number;
      isFreshCapture?: boolean;
      detectedLabels?: string[];
      motionCycles?: number;
      poseConfidence?: number;
      fileSizeBytes?: number;
    };
  }) {
    const db = DatabaseService.getDb();
    const mission = MissionsService.getById(params.missionId);
    if (!mission) throw new Error('Mission not found');

    // Idempotency: If mission already completed, return existing success
    if (mission.status === 'COMPLETED') {
      return {
        isValid: true,
        strategyUsed: 'BasicVerificationProvider',
        confidenceScore: 1.0,
        verificationStatus: 'PASSED',
        rejectionReason: null,
        completedMission: mission
      };
    }

    const taskRow = db.prepare('SELECT * FROM tasks WHERE id = ?').get(mission.taskId) as any;
    const validationRules = JSON.parse(taskRow?.validation_rules || '{}');

    // Run Basic Verification Provider first
    const basicCheck = BasicVerificationProvider.verify({
      proofType: taskRow?.proof_type || 'PHOTO',
      mimeType: params.mediaType,
      fileSizeBytes: params.deviceTelemetry?.fileSizeBytes ?? 1024,
      durationSeconds: params.deviceTelemetry?.durationSeconds ?? 10,
      capturedAt: params.capturedAt,
      rules: {
        minDurationSeconds: validationRules.minDurationSec || 10,
        maxDurationSeconds: validationRules.maxDurationSec || 60,
        minLuminanceLux: validationRules.minLuminance || 25,
        minRepetitions: validationRules.minRepetitions
      },
      telemetry: params.deviceTelemetry
    });

    let verificationResult = {
      isValid: basicCheck.status === 'ACCEPTED',
      strategyUsed: 'BasicVerificationProvider',
      rejectionReason: basicCheck.reasonMessage,
      confidenceScore: basicCheck.confidence,
      extractedMetrics: {}
    };

    // If basic checks pass and more complex rules exist, run VerificationEngine
    if (verificationResult.isValid) {
      verificationResult = VerificationEngine.verify({
        taskSlug: taskRow?.slug || '',
        proofType: taskRow?.proof_type || 'PHOTO',
        mediaType: params.mediaType,
        capturedAt: params.capturedAt,
        deviceTelemetry: params.deviceTelemetry || {},
        validationRules
      });
    }

    const proofId = uuidv4();
    const verificationStatus = verificationResult.isValid ? 'PASSED' : 'REJECTED';
    const now = new Date().toISOString();

    // Persist Proof Record
    db.prepare(`
      INSERT INTO proofs (id, mission_id, media_type, storage_key, captured_at, device_telemetry, verification_status, rejection_reason, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      proofId,
      params.missionId,
      params.mediaType,
      params.storageKey,
      params.capturedAt,
      JSON.stringify(params.deviceTelemetry || {}),
      verificationStatus,
      verificationResult.rejectionReason,
      now
    );

    // If Valid -> Complete Mission
    let completedMission = null;
    if (verificationResult.isValid) {
      completedMission = MissionsService.completeMission(params.missionId);
    } else {
      // If Rejected -> Mission remains in AWAITING_PROOF
      db.prepare("UPDATE missions SET status = 'AWAITING_PROOF', updated_at = ? WHERE id = ?").run(now, params.missionId);
    }

    return {
      proofId,
      isValid: verificationResult.isValid,
      strategyUsed: verificationResult.strategyUsed,
      confidenceScore: verificationResult.confidenceScore,
      verificationStatus,
      rejectionReason: verificationResult.rejectionReason,
      completedMission,
      rewards: {
        totalXp: completedMission ? (taskRow?.base_xp || 50) : 0
      }
    };
  }

  public static getById(proofId: string) {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM proofs WHERE id = ?').get(proofId) as any;
    if (!row) return null;

    const storageEndpoint = process.env.STORAGE_ENDPOINT || 'http://localhost:9000';
    const bucket = process.env.STORAGE_BUCKET || 'habitat-proofs';
    const publicUrl = `${storageEndpoint}/${bucket}/${row.storage_key}`;

    return {
      id: row.id,
      missionId: row.mission_id,
      mediaType: row.media_type,
      storageKey: row.storage_key,
      publicUrl,
      capturedAt: row.captured_at,
      deviceTelemetry: JSON.parse(row.device_telemetry || '{}'),
      verificationStatus: row.verification_status,
      rejectionReason: row.rejection_reason,
      createdAt: row.created_at
    };
  }

  public static retryProof(proofId: string) {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    db.prepare("UPDATE proofs SET verification_status = 'CAPTURING', rejection_reason = NULL, updated_at = ? WHERE id = ?").run(now, proofId);
    return this.getById(proofId);
  }

  public static deleteProof(proofId: string) {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    db.prepare("UPDATE proofs SET verification_status = 'DELETED', updated_at = ? WHERE id = ?").run(now, proofId);
    return true;
  }
}

export const proofsController = Router();

// POST /api/v1/missions/:id/proofs
proofsController.post('/missions/:id/proofs', (req: Request, res: Response) => {
  try {
    const missionId = String(req.params.id);
    const { type, userId } = req.body;
    const proof = ProofsService.createProof(missionId, userId || 'default-user', type || 'PHOTO');
    res.status(201).json({ success: true, data: proof });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/proofs/upload-url
proofsController.post('/upload-url', (req: Request, res: Response) => {
  try {
    const { userId, missionId, mediaType, extension } = req.body;
    if (!userId || !missionId || !mediaType) {
      res.status(400).json({ success: false, error: 'userId, missionId, and mediaType are required' });
      return;
    }

    const uploadInfo = ProofsService.generateUploadUrl({ userId, missionId, mediaType, extension });
    res.json({ success: true, data: uploadInfo });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/proofs/:id/assets
proofsController.post('/:id/assets', (req: Request, res: Response) => {
  try {
    const proofId = String(req.params.id);
    const assetSession = ProofsService.addProofAsset(proofId, req.body);
    res.status(201).json({ success: true, data: assetSession });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/missions/:id/proof or POST /api/v1/proofs
proofsController.post('/:id/proof', async (req: Request, res: Response) => {
  try {
    const missionId = String(req.params.id);
    const { mediaType, storageKey, capturedAt, deviceTelemetry } = req.body;

    if (!mediaType || !storageKey) {
      res.status(400).json({ success: false, error: 'mediaType and storageKey are required' });
      return;
    }

    const result = await ProofsService.submitAndVerify({
      missionId,
      mediaType,
      storageKey,
      capturedAt: capturedAt || new Date().toISOString(),
      deviceTelemetry: deviceTelemetry || {}
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

// POST /api/v1/proofs/:id/retry
proofsController.post('/:id/retry', (req: Request, res: Response) => {
  const retried = ProofsService.retryProof(String(req.params.id));
  res.json({ success: true, data: retried });
});

// DELETE /api/v1/proofs/:id
proofsController.delete('/:id', (req: Request, res: Response) => {
  ProofsService.deleteProof(String(req.params.id));
  res.json({ success: true, message: 'Proof deleted' });
});
