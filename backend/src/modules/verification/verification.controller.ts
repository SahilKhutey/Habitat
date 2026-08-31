// Authoritative Verification & Truth Engine Controller
import { Router, Request, Response } from 'express';
import { VerificationTruthService } from './verification.service';
import { SessionChallengeService } from '../proofs/services/session-challenge.service';
import { VerificationEngine } from './verification.engine';
import { EvidenceVerificationEngine } from './engine/evidence-verification.engine';

export const verificationController = Router();

// POST /api/v1/verification/challenge - Issue single-use proof challenge nonce
verificationController.post('/challenge', (req: Request, res: Response) => {
  try {
    const { missionId, userId } = req.body;
    if (!missionId || !userId) {
      res.status(400).json({ success: false, error: 'missionId and userId are required' });
      return;
    }

    const challenge = SessionChallengeService.issueChallenge(String(missionId), String(userId));
    res.json({ success: true, data: challenge });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/verification/verify-media - Authoritative Server-Side Vision Verification on Raw Media
verificationController.post('/verify-media', async (req: Request, res: Response) => {
  try {
    const { missionId, proofId, sessionId, sessionNonce, taskSlug, frames, startedAt, endedAt, policy } = req.body;

    if (!missionId || !sessionId || !sessionNonce || !frames || !Array.isArray(frames)) {
      res.status(400).json({
        success: false,
        error: 'missionId, sessionId, sessionNonce, and frames array are required'
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
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/verification/verify-evidence-v2 - Authoritative Phase 14 Evidence Verification
verificationController.post('/verify-evidence-v2', (req: Request, res: Response) => {
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
verificationController.post('/verify-evidence', (req: Request, res: Response) => {
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
verificationController.post('/evaluate', (req: Request, res: Response) => {
  try {
    const { missionId, proofId, telemetry } = req.body;
    if (!missionId) {
      res.status(400).json({ success: false, error: 'missionId is required' });
      return;
    }

    const result = VerificationTruthService.evaluateProof({
      missionId,
      proofId,
      telemetry
    });

    res.json({ success: true, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/missions/:id/verify
verificationController.post('/:id/verify', (req: Request, res: Response) => {
  try {
    const { proofId, telemetry } = req.body;
    const result = VerificationTruthService.evaluateProof({
      missionId: String(req.params.id),
      proofId,
      telemetry
    });

    res.json({ success: true, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/missions/:id/verification-report
verificationController.get('/:id/verification-report', (req: Request, res: Response) => {
  const report = VerificationTruthService.getReport(String(req.params.id));
  if (!report) {
    res.status(404).json({ success: false, error: 'Verification report not found' });
    return;
  }
  res.json({ success: true, data: report });
});
