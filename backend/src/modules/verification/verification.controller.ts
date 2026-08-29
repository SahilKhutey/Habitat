// Authoritative Verification & Truth Engine Controller
import { Router, Request, Response } from 'express';
import { VerificationTruthService } from './verification.service';
import { SessionChallengeService } from '../proofs/services/session-challenge.service';
import { VerificationEngine } from './verification.engine';

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
