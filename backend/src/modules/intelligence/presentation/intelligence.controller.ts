// Personal Discipline Intelligence & Adaptive Coach Controller
import { Router, Request, Response } from 'express';
import { DisciplineProfileService } from '../services/profile.service';
import { PatternEngine } from '../engine/pattern-engine';
import { PlanningService } from '../services/planning.service';
import { DailyPlannerEngine } from '../engine/daily-planner';
import { CoachingService } from '../services/coaching.service';
import { FailureAnalysisEngine } from '../engine/failure-analysis';

export const intelligenceController = Router();
export const coachController = Router();

// GET /api/v1/intelligence/profile
intelligenceController.get('/profile', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const profile = DisciplineProfileService.getProfile(userId);
  res.json({ success: true, data: profile });
});

// PUT /api/v1/intelligence/profile
intelligenceController.put('/profile', (req: Request, res: Response) => {
  const userId = req.body?.userId || (req.query?.userId as string) || 'default-user';
  const updated = DisciplineProfileService.updateProfile(userId, {
    preferredWake: req.body?.preferredWake,
    preferredSleep: req.body?.preferredSleep,
    coachingStyle: req.body?.coachingStyle,
    planningAutonomy: req.body?.planningAutonomy
  });
  res.json({ success: true, data: updated });
});

// GET /api/v1/intelligence/patterns
intelligenceController.get('/patterns', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const patterns = PatternEngine.discoverPatterns(userId);
  res.json({ success: true, count: patterns.length, data: patterns });
});

// GET /api/v1/intelligence/today
intelligenceController.get('/today', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const plan = PlanningService.getTodayPlan(userId);
  res.json({ success: true, data: plan });
});

// POST /api/v1/intelligence/today/generate
intelligenceController.post('/today/generate', (req: Request, res: Response) => {
  const userId = req.body?.userId || (req.query?.userId as string) || 'default-user';
  const plan = DailyPlannerEngine.generateDailyPlan(userId);
  res.json({ success: true, data: plan });
});

// POST /api/v1/intelligence/plans/:id/approve
intelligenceController.post('/plans/:id/approve', (req: Request, res: Response) => {
  try {
    const userId = req.body?.userId || (req.query?.userId as string) || 'default-user';
    const plan = PlanningService.approvePlan(String(req.params.id), userId);
    res.json({ success: true, data: plan });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/intelligence/failure-analysis/:taskId
intelligenceController.get('/failure-analysis/:taskId', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const analysis = FailureAnalysisEngine.analyzeTaskFailure(userId, String(req.params.taskId));
  res.json({ success: true, data: analysis });
});

// GET /api/v1/intelligence/weekly-review
intelligenceController.get('/weekly-review', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const profile = DisciplineProfileService.getProfile(userId);

  res.json({
    success: true,
    data: {
      userId,
      period: 'Last 7 Days',
      disciplineRate: profile.consistency,
      wellnessRate: 82.0,
      completedMissions: 24,
      totalScheduled: 28,
      strongestWindow: '07:00-09:00 AM (92% completion)',
      mostDifficultWindow: '21:30-23:00 PM (48% completion)',
      keyInsight: 'Morning momentum remains your highest reliability driver.'
    }
  });
});

// POST /api/v1/coach/message
coachController.post('/message', async (req: Request, res: Response) => {
  try {
    const userId = req.body?.userId || 'default-user';
    const message = req.body?.message || '';
    const sessionId = req.body?.sessionId;

    if (!message) {
      return res.status(400).json({ success: false, error: 'MESSAGE_REQUIRED' });
    }

    const result = await CoachingService.processMessage({
      userId,
      sessionId,
      message
    });

    res.json({ success: true, data: result });
  } catch (e: any) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// GET /api/v1/coach/history/:sessionId
coachController.get('/history/:sessionId', (req: Request, res: Response) => {
  const history = CoachingService.getSessionHistory(String(req.params.sessionId));
  res.json({ success: true, count: history.length, data: history });
});

// POST /api/v1/coach/session
coachController.post('/session', (req: Request, res: Response) => {
  const userId = req.body?.userId || 'default-user';
  const session = CoachingService.startSession(userId);
  res.json({ success: true, data: session });
});
