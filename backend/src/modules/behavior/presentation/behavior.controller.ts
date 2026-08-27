// Behavior Event Ingestion & Pattern REST Controller
import { Router, Request, Response } from 'express';
import { BehaviorEngine } from '../engine/behavior-engine';
import { TimingEngine } from '../engine/timing-engine';

export const behaviorController = Router();

// POST /api/v1/behavior/events - Ingest behavioral event idempotently
behaviorController.post('/events', (req: Request, res: Response) => {
  try {
    const userId = req.body?.userId || (req.query?.userId as string) || 'default-user';
    const type = req.body?.type;
    if (!type) {
      return res.status(400).json({ success: false, error: 'EVENT_TYPE_REQUIRED' });
    }

    const result = BehaviorEngine.recordEvent({
      userId,
      type,
      missionId: req.body?.missionId,
      taskId: req.body?.taskId,
      routineId: req.body?.routineId,
      timestamp: req.body?.timestamp ? new Date(req.body.timestamp) : new Date(),
      metadata: req.body?.metadata,
      idempotencyKey: req.body?.idempotencyKey
    });

    res.status(result.isDuplicate ? 200 : 201).json({
      success: true,
      data: {
        recorded: result.recorded,
        isDuplicate: result.isDuplicate,
        eventId: result.eventId
      }
    });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/behavior/patterns - Get timing and behavioral patterns
behaviorController.get('/patterns', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const taskId = req.query?.taskId as string | undefined;

  const hourly = TimingEngine.calculateSuccessByHour(userId, taskId);
  const optimal = TimingEngine.findOptimalWindow(userId, taskId);

  res.json({
    success: true,
    data: {
      userId,
      taskId,
      optimalWindow: optimal.bestWindow,
      bestSuccessRate: optimal.bestSuccessRate,
      recommendation: optimal.recommendation,
      hourly
    }
  });
});
