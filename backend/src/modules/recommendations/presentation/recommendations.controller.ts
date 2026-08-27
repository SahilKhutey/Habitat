// Personalized Recommendations & Consent REST Controller
import { Router, Request, Response } from 'express';
import { RecommendationEngine } from '../engine/recommendation-engine';

export const recommendationsController = Router();

// GET /api/v1/recommendations - List active ranked recommendations (max 3)
recommendationsController.get('/', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const recommendations = RecommendationEngine.getActiveRecommendations(userId);
  res.json({ success: true, count: recommendations.length, data: recommendations });
});

// POST /api/v1/recommendations/:id/accept - Accept recommendation
recommendationsController.post('/:id/accept', (req: Request, res: Response) => {
  try {
    const userId = req.body?.userId || (req.query?.userId as string) || 'default-user';
    const result = RecommendationEngine.acceptRecommendation(String(req.params.id), userId);
    res.json({ success: true, message: result.message });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/recommendations/:id/decline - Decline recommendation
recommendationsController.post('/:id/decline', (req: Request, res: Response) => {
  try {
    const userId = req.body?.userId || (req.query?.userId as string) || 'default-user';
    const result = RecommendationEngine.declineRecommendation(String(req.params.id), userId);
    res.json({ success: true, message: result.message });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/recommendations/:id/dismiss - Dismiss recommendation
recommendationsController.post('/:id/dismiss', (req: Request, res: Response) => {
  try {
    const userId = req.body?.userId || (req.query?.userId as string) || 'default-user';
    const result = RecommendationEngine.dismissRecommendation(String(req.params.id), userId);
    res.json({ success: true, message: result.message });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});
