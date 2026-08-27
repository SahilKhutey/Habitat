// Authoritative Mission & Discipline Engine Controller
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { MissionService } from './mission.service';

export const missionRouter = Router();

// GET /api/v1/missions/current
missionRouter.get('/current', (req: Request, res: Response) => {
  const db = DatabaseService.getDb();
  const defaultUser = db.prepare('SELECT id FROM users LIMIT 1').get() as any;
  const userId = (req.query.userId as string) || defaultUser?.id || 'default-user';

  const mission = MissionService.getCurrentMission(userId);
  res.json({ success: true, mission });
});

// POST /api/v1/missions
missionRouter.post('/', (req: Request, res: Response) => {
  try {
    const { userId, taskId, alarmId, scheduledAt, disciplineMode } = req.body;
    if (!taskId) {
      res.status(400).json({ success: false, error: 'taskId is required' });
      return;
    }

    const mission = MissionService.createMission({
      userId: userId || 'default-user',
      taskId,
      alarmId,
      scheduledAt,
      disciplineMode
    });

    res.status(201).json({ success: true, data: mission });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/missions/:id
missionRouter.get('/:id', (req: Request, res: Response) => {
  const mission = MissionService.getById(String(req.params.id));
  if (!mission) {
    res.status(404).json({ success: false, error: 'Mission not found' });
    return;
  }
  res.json({ success: true, data: mission });
});

// POST /api/v1/missions/:id/start
missionRouter.post('/:id/start', (req: Request, res: Response) => {
  try {
    const mission = MissionService.startMission(String(req.params.id));
    res.json({ success: true, data: mission });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/missions/:id/submit
missionRouter.post('/:id/submit', (req: Request, res: Response) => {
  try {
    const mission = MissionService.submitMission(String(req.params.id), undefined, req.body);
    res.json({ success: true, data: mission });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/missions/:id/complete
missionRouter.post('/:id/complete', (req: Request, res: Response) => {
  try {
    const mission = MissionService.completeMission(String(req.params.id));
    res.json({ success: true, data: mission });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/missions/:id/retry
missionRouter.post('/:id/retry', (req: Request, res: Response) => {
  try {
    const { reason } = req.body;
    const mission = MissionService.retryMission(String(req.params.id), reason);
    res.json({ success: true, data: mission });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/missions/:id/cancel
missionRouter.post('/:id/cancel', (req: Request, res: Response) => {
  try {
    const { reason } = req.body;
    const mission = MissionService.cancelMission(String(req.params.id), reason);
    res.json({ success: true, data: mission });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/missions/:id/events
missionRouter.get('/:id/events', (req: Request, res: Response) => {
  const events = MissionService.getEvents(String(req.params.id));
  res.json({ success: true, count: events.length, data: events });
});
