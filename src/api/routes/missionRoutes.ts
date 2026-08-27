// Missions REST Routes (State Machine Endpoints)
import { Router, Request, Response, NextFunction } from 'express';
import { MissionRepository } from '../../db/repositories/missionRepository';
import { UserRepository } from '../../db/repositories/userRepository';
import { TaskRepository } from '../../db/repositories/taskRepository';
import { MissionService } from '../../services/missionService';
import { z } from 'zod';
import { validate } from '../middleware/validate';

export const missionRouter = Router();

// GET /api/missions/active - Get currently active / triggered mission for lock screen
missionRouter.get('/active', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || UserRepository.getFirstUser()?.id;
  if (!userId) {
    res.status(400).json({ success: false, error: 'User ID required' });
    return;
  }

  const activeMission = MissionRepository.getActiveMission(userId);
  if (!activeMission) {
    res.json({ success: true, active: false, mission: null });
    return;
  }

  const task = TaskRepository.getById(activeMission.taskId);
  const attempts = MissionRepository.getAttempts(activeMission.id);

  res.json({
    success: true,
    active: true,
    mission: activeMission,
    task,
    attempts
  });
});

// GET /api/missions/today - Get missions for current day
missionRouter.get('/today', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || UserRepository.getFirstUser()?.id;
  if (!userId) {
    res.status(400).json({ success: false, error: 'User ID required' });
    return;
  }

  const todayStr = new Date().toISOString().substring(0, 10);
  const missions = MissionRepository.getTodaysMissions(userId, todayStr);

  res.json({ success: true, count: missions.length, missions });
});

// GET /api/missions/:id - Get mission details
missionRouter.get('/:id', (req: Request, res: Response) => {
  const missionId = String(req.params.id);
  const mission = MissionRepository.getById(missionId);
  if (!mission) {
    res.status(404).json({ success: false, error: 'Mission not found' });
    return;
  }

  const task = TaskRepository.getById(mission.taskId);
  const attempts = MissionRepository.getAttempts(mission.id);

  res.json({ success: true, mission, task, attempts });
});

const triggerMissionSchema = z.object({
  userId: z.string().uuid().optional(),
  taskId: z.string().uuid(),
  disciplineMode: z.enum(['GENTLE', 'DISCIPLINE', 'HARDCORE']).default('DISCIPLINE')
});

// POST /api/missions/trigger - Manually / programmatically fire a mission
missionRouter.post('/trigger', validate(triggerMissionSchema), async (req: Request, res: Response, next: NextFunction) => {
  try {
    const defaultUser = UserRepository.getFirstUser();
    const userId = req.body.userId || defaultUser?.id;

    if (!userId) {
      res.status(400).json({ success: false, error: 'User not found' });
      return;
    }

    const mission = await MissionService.triggerMission({
      userId,
      taskId: req.body.taskId,
      disciplineMode: req.body.disciplineMode
    });

    const task = TaskRepository.getById(mission.taskId);

    res.status(201).json({ success: true, mission, task });
  } catch (error) {
    next(error);
  }
});

// POST /api/missions/:id/start - Acknowledge alarm and start proof capture
missionRouter.post('/:id/start', (req: Request, res: Response, next: NextFunction) => {
  try {
    const missionId = String(req.params.id);
    const updated = MissionService.startMission(missionId);
    res.json({ success: true, mission: updated });
  } catch (error) {
    next(error);
  }
});
