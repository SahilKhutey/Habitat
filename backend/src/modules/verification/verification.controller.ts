// Authoritative Verification & Truth Engine Controller
import { Router, Request, Response } from 'express';
import { VerificationTruthService } from './verification.service';

export const verificationController = Router();

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
