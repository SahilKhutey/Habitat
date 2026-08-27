// Analytics, Insights & Task Adaptation Preview REST Controller
import { Router, Request, Response } from 'express';
import { AnalyticsEngine } from '../engine/analytics-engine';
import { BehaviorEngine } from '../../behavior/engine/behavior-engine';
import { OverloadEngine } from '../../adaptation/engine/overload-engine';
import { DatabaseService } from '../../../db/connection';

export const analyticsController = Router();
export const insightsController = Router();
export const taskAdaptationController = Router();

// GET /api/v1/analytics/overview
analyticsController.get('/overview', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const overview = AnalyticsEngine.getOverview(userId);
  res.json({ success: true, data: overview });
});

// GET /api/v1/analytics/tasks/:id
analyticsController.get('/tasks/:id', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const performance = BehaviorEngine.calculateTaskPerformance({
    userId,
    taskTemplateId: String(req.params.id)
  });
  res.json({ success: true, data: performance });
});

// GET /api/v1/analytics/routines/:id
analyticsController.get('/routines/:id', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const load = OverloadEngine.analyzeRoutineLoad(String(req.params.id), userId);
  res.json({ success: true, data: load });
});

// GET /api/v1/insights
insightsController.get('/', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const overview = AnalyticsEngine.getOverview(userId);
  res.json({ success: true, data: overview });
});

// POST /api/v1/tasks/:id/adaptation-preview
taskAdaptationController.post('/:id/adaptation-preview', (req: Request, res: Response) => {
  const userId = req.body?.userId || (req.query?.userId as string) || 'default-user';
  const db = DatabaseService.getDb();
  const taskId = String(req.params.id);

  const task = db.prepare('SELECT * FROM tasks WHERE id = ?').get(taskId) as any;
  const currentDiff = task?.difficulty || 2;

  const performance = BehaviorEngine.calculateTaskPerformance({
    userId,
    taskTemplateId: taskId
  });

  let recommendedDiff = currentDiff;
  let reason = 'Task performance is balanced.';
  let confidence = 0.85;

  if (performance.attempts >= 5 && performance.successRate >= 95) {
    recommendedDiff = Math.min(5, currentDiff + 1);
    reason = `High completion consistency (${performance.successRate}%) over ${performance.attempts} missions.`;
    confidence = 0.90;
  } else if (performance.attempts >= 5 && performance.successRate < 45) {
    recommendedDiff = Math.max(1, currentDiff - 1);
    reason = `Challenging completion rate (${performance.successRate}%). Lowering difficulty will help rebuild momentum.`;
    confidence = 0.88;
  }

  res.json({
    success: true,
    data: {
      taskId,
      current: {
        difficulty: currentDiff
      },
      recommended: {
        difficulty: recommendedDiff
      },
      confidence,
      reason,
      performance
    }
  });
});
