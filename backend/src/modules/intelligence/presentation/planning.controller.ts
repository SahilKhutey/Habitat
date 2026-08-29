// Planning Controller
import { Router, Request, Response } from 'express';
import { PlanningService } from '../services/planning.service';
import { DailyPlannerEngine } from '../engine/daily-planner';

export const planningController = Router();

planningController.get('/today', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const plan = PlanningService.getTodayPlan(userId);
  res.json({ success: true, data: plan });
});

planningController.post('/today/generate', (req: Request, res: Response) => {
  const userId = req.body?.userId || 'default-user';
  const plan = DailyPlannerEngine.generateDailyPlan(userId);
  res.json({ success: true, data: plan });
});

planningController.post('/:id/approve', (req: Request, res: Response) => {
  try {
    const userId = req.body?.userId || 'default-user';
    const plan = PlanningService.approvePlan(String(req.params.id), userId);
    res.json({ success: true, data: plan });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});
