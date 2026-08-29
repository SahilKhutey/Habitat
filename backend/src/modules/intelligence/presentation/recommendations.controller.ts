// Recommendations Controller
import { Router, Request, Response } from 'express';
import { RecommendationService } from '../services/recommendation.service';

export const recommendationsController = Router();

recommendationsController.get('/', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const recs = RecommendationService.getRecommendations(userId);
  res.json({ success: true, count: recs.length, data: recs });
});

recommendationsController.post('/:id/accept', (req: Request, res: Response) => {
  const userId = req.body?.userId || 'default-user';
  const result = RecommendationService.acceptRecommendation(String(req.params.id), userId);
  res.json({ success: true, data: result });
});

recommendationsController.post('/:id/reject', (req: Request, res: Response) => {
  const userId = req.body?.userId || 'default-user';
  const result = RecommendationService.rejectRecommendation(String(req.params.id), userId);
  res.json({ success: true, data: result });
});
