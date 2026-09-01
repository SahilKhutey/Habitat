// Authoritative Verification & Truth Engine Controller
import { Router, Request, Response } from 'express';
import { VerificationTruthService } from './verification.service';
import { SessionChallengeService } from '../proofs/services/session-challenge.service';
import { VerificationEngine } from './verification.engine';
import { EvidenceVerificationEngine } from './engine/evidence-verification.engine';
import { authGuard, AuthenticatedRequest } from '../../common/guards/auth.guard';
import { SecurityService } from '../security/security.service';
import { MissionsService } from '../missions/missions.controller';

export const verificationController = Router();

// POST /api/v1/verification/challenge - Issue single-use proof challenge nonce
verificationController.post('/challenge', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.userId;
    const { missionId } = req.body;
    if (!missionId) {
      res.status(400).json({ success: false, error: 'missionId is required' });
      return;
    }

    const mission = MissionsService.getById(String(missionId));
    if (!mission) {
      res.status(404).json({ success: false, error: 'MISSION_NOT_FOUND: Mission not found' });
      return;
    }

    if (mission.userId && mission.userId !== userId) {
      res.status(403).json({
        success: false,
        error: `FORBIDDEN_IDOR_VIOLATION: User ${userId} is not authorized to request challenge for mission owned by ${mission.userId}`
      });
      return;
    }

    const challenge = SessionChallengeService.issueChallenge(String(missionId), userId);
    res.json({ success: true, data: challenge });
  } catch (e: any) {
    const statusCode = e.message?.includes('FORBIDDEN_IDOR_VIOLATION') ? 403 : 400;
    res.status(statusCode).json({ success: false, error: e.message });
  }
});

// POST /api/v1/verification/verify-media - Authoritative Server-Side Vision Verification on Raw Media
verificationController.post('/verify-media', authGuard, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.userId;

    // Rate limit: 10 verification requests per minute per user
    const rateCheck = SecurityService.checkRateLimit(`verify_media_${userId}`, 10, 60);
    if (!rateCheck.allowed) {
      res.status(429).json({
        success: false,
        error: 'Too many verification requests. Rate limit exceeded. Please wait before retrying.'
      });
      return;
    }

    const { missionId, proofId, sessionId, sessionNonce, taskSlug, frames, startedAt, endedAt, policy } = req.body;

    if (!missionId || !sessionId || !sessionNonce || !frames || !Array.isArray(frames)) {
      res.status(400).json({
        success: false,
        error: 'missionId, sessionId, sessionNonce, and frames array are required'
      });
      return;
    }

    const mission = MissionsService.getById(String(missionId));
    if (!mission) {
      res.status(404).json({ success: false, error: 'MISSION_NOT_FOUND: Mission not found' });
      return;
    }

    if (mission.userId && mission.userId !== userId) {
      res.status(403).json({
        success: false,
        error: `FORBIDDEN_IDOR_VIOLATION: User ${userId} is not authorized to verify media for mission owned by ${mission.userId}`
      });
      return;
    }

    // Convert frame data if passed as base64 or arrays to Uint8Array
    const formattedFrames = frames.map((f: any) => {
      let data: Uint8Array;
      if (typeof f.data === 'string') {
        data = Buffer.from(f.data, 'base64');
      } else if (Array.isArray(f.data)) {
        data = new Uint8Array(f.data);
      } else if (f.data instanceof Uint8Array || Buffer.isBuffer(f.data)) {
        data = f.data;
      } else {
        data = new Uint8Array(192 * 192 * 3);
      }
      return {
        timestampMs: Number(f.timestampMs || 0),
        frameIndex: Number(f.frameIndex || 0),
        frameHash: String(f.frameHash || ''),
        width: Number(f.width || 192),
        height: Number(f.height || 192),
        data
      };
    });

    const result = await VerificationTruthService.evaluateMediaProof({
      missionId: String(missionId),
      proofId: proofId ? String(proofId) : undefined,
      sessionId: String(sessionId),
      sessionNonce: String(sessionNonce),
      taskSlug: taskSlug ? String(taskSlug) : 'tpl-pushups-10',
      frames: formattedFrames,
      startedAt: startedAt ? Number(startedAt) : undefined,
      endedAt: endedAt ? Number(endedAt) : undefined,
      policy
    });

    const statusCode = result.verification.decision === 'ACCEPT' ? 200 : 422;
    res.status(statusCode).json({
      success: result.verification.decision === 'ACCEPT',
      data: result
    });
  } catch (e: any) {
    const statusCode = e.message?.includes('FORBIDDEN_IDOR_VIOLATION') ? 403 : 400;
    res.status(statusCode).json({ success: false, error: e.message });
  }
});

// POST /api/v1/verification/verify-evidence-v2 - Authoritative Phase 14 Evidence Verification
verificationController.post('/verify-evidence-v2', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const { evidence, policy } = req.body;
    if (!evidence) {
      res.status(400).json({ success: false, error: 'Evidence payload is required' });
      return;
    }

    const result = EvidenceVerificationEngine.verify(evidence, policy);
    const statusCode = result.accepted ? 200 : 422;
    res.status(statusCode).json({ success: result.accepted, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/verification/verify-evidence - Evaluate cryptographic VerificationEvidence packet
verificationController.post('/verify-evidence', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const { evidence, policy } = req.body;
    if (!evidence || !evidence.sessionId || !evidence.sessionNonce) {
      res.status(400).json({ success: false, error: 'Valid VerificationEvidence with sessionId and sessionNonce is required' });
      return;
    }

    const result = VerificationEngine.verifyEvidence(evidence, policy);
    res.json({ success: true, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/verification/evaluate
verificationController.post('/evaluate', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.userId;
    const { missionId, proofId, telemetry } = req.body;
    if (!missionId) {
      res.status(400).json({ success: false, error: 'missionId is required' });
      return;
    }

    const mission = MissionsService.getById(String(missionId));
    if (mission && mission.userId && mission.userId !== userId) {
      res.status(403).json({
        success: false,
        error: `FORBIDDEN_IDOR_VIOLATION: User ${userId} is not authorized to evaluate proof for mission owned by ${mission.userId}`
      });
      return;
    }

    const result = VerificationTruthService.evaluateProof({
      missionId,
      proofId,
      telemetry
    });

    res.json({ success: true, data: result });
  } catch (e: any) {
    const statusCode = e.message?.includes('FORBIDDEN_IDOR_VIOLATION') ? 403 : 400;
    res.status(statusCode).json({ success: false, error: e.message });
  }
});

// POST /api/v1/missions/:id/verify
verificationController.post('/:id/verify', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.userId;
    const { proofId, telemetry } = req.body;
    const missionId = String(req.params.id);

    const mission = MissionsService.getById(missionId);
    if (mission && mission.userId && mission.userId !== userId) {
      res.status(403).json({
        success: false,
        error: `FORBIDDEN_IDOR_VIOLATION: User ${userId} is not authorized to verify mission owned by ${mission.userId}`
      });
      return;
    }

    const result = VerificationTruthService.evaluateProof({
      missionId,
      proofId,
      telemetry
    });

    res.json({ success: true, data: result });
  } catch (e: any) {
    const statusCode = e.message?.includes('FORBIDDEN_IDOR_VIOLATION') ? 403 : 400;
    res.status(statusCode).json({ success: false, error: e.message });
  }
});

// GET /api/v1/missions/:id/verification-report
verificationController.get('/:id/verification-report', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.userId;
    const missionId = String(req.params.id);

    const mission = MissionsService.getById(missionId);
    if (mission && mission.userId && mission.userId !== userId) {
      res.status(403).json({
        success: false,
        error: `FORBIDDEN_IDOR_VIOLATION: User ${userId} is not authorized to view verification report for mission owned by ${mission.userId}`
      });
      return;
    }

    const report = VerificationTruthService.getReport(missionId);
    if (!report) {
      res.status(404).json({ success: false, error: 'Verification report not found' });
      return;
    }
    res.json({ success: true, data: report });
  } catch (e: any) {
    const statusCode = e.message?.includes('FORBIDDEN_IDOR_VIOLATION') ? 403 : 400;
    res.status(statusCode).json({ success: false, error: e.message });
  }
});
