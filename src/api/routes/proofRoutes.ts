// Proof Ingestion & Verification Routes
import { Router, Request, Response, NextFunction } from 'express';
import multer from 'multer';
import * as path from 'path';
import * as fs from 'fs';
import { MissionService } from '../../services/missionService';
import { ProofRepository } from '../../db/repositories/proofRepository';

export const proofRouter = Router();

// Configure local uploads storage
const UPLOADS_DIR = path.resolve(process.cwd(), 'uploads');
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, UPLOADS_DIR);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || (file.mimetype.includes('video') ? '.mp4' : '.jpg');
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `proof-${uniqueSuffix}${ext}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 50 * 1024 * 1024 } // 50 MB max
});

// POST /api/missions/:id/proof - Submit photo or video proof
proofRouter.post(
  '/:id/proof',
  upload.single('media'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const missionId = String(req.params.id);
      let mediaType: 'image/jpeg' | 'video/mp4' = 'image/jpeg';
      let storageUrl = '';

      if (req.file) {
        mediaType = req.file.mimetype.includes('video') ? 'video/mp4' : 'image/jpeg';
        storageUrl = `/uploads/${req.file.filename}`;
      } else if (req.body.storageUrl) {
        storageUrl = req.body.storageUrl;
        mediaType = req.body.mediaType || 'image/jpeg';
      } else {
        res.status(400).json({ success: false, error: 'Media file or storageUrl is required' });
        return;
      }

      const ambientLux = req.body.ambientLux ? parseFloat(req.body.ambientLux) : 50;
      const accelerometerMotion = req.body.accelerometerMotion !== undefined 
        ? req.body.accelerometerMotion === 'true' || req.body.accelerometerMotion === true 
        : true;

      const verification = await MissionService.submitAndVerifyProof(missionId, {
        missionId,
        mediaType,
        storageUrl,
        capturedAt: req.body.capturedAt || new Date().toISOString(),
        deviceMetadata: {
          ambientLux,
          accelerometerMotion,
          appVersion: req.body.appVersion || '1.0.0-mvp'
        }
      });

      if (!verification.isValid) {
        res.status(400).json({
          success: false,
          verified: false,
          error: 'Verification Failed',
          rejectionReason: verification.rejectionReason,
          proof: verification.proof
        });
        return;
      }

      res.status(200).json({
        success: true,
        verified: true,
        mission: verification.mission,
        proof: verification.proof,
        rewards: verification.xpResult
      });
    } catch (error) {
      next(error);
    }
  }
);

// GET /api/missions/:id/proofs - List all submitted proofs for a mission
proofRouter.get('/:id/proofs', (req: Request, res: Response) => {
  const missionId = String(req.params.id);
  const proofs = ProofRepository.getByMissionId(missionId);
  res.json({ success: true, count: proofs.length, proofs });
});
