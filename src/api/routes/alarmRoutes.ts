// Alarms REST Routes (Mission Commitments)
import { Router, Request, Response } from 'express';
import { AlarmRepository } from '../../db/repositories/alarmRepository';
import { UserRepository } from '../../db/repositories/userRepository';
import { z } from 'zod';
import { validate } from '../middleware/validate';

export const alarmRouter = Router();

// GET /api/alarms - List alarms for user
alarmRouter.get('/', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || UserRepository.getFirstUser()?.id;
  if (!userId) {
    res.status(400).json({ success: false, error: 'User ID required' });
    return;
  }

  const alarms = AlarmRepository.getAllByUser(userId);
  res.json({ success: true, count: alarms.length, alarms });
});

const createAlarmSchema = z.object({
  userId: z.string().uuid().optional(),
  taskId: z.string().uuid(),
  timeOfDay: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)(:[0-5]\d)?$/, 'Format must be HH:MM or HH:MM:SS'),
  repeatDays: z.array(z.number().int().min(0).max(6)).default([1, 2, 3, 4, 5]), // Default weekdays
  disciplineMode: z.enum(['GENTLE', 'DISCIPLINE', 'HARDCORE']).default('DISCIPLINE'),
  retryIntervalMinutes: z.number().int().min(1).max(30).default(5),
  escalationEnabled: z.boolean().default(true),
  soundPack: z.enum(['TACTICAL_SIREN', 'ZEN_BELLS', 'PULSE', 'MILITARY_BUGLE']).default('TACTICAL_SIREN'),
  isActive: z.boolean().default(true)
});

// POST /api/alarms - Create new scheduled mission commitment
alarmRouter.post('/', validate(createAlarmSchema), (req: Request, res: Response) => {
  const defaultUser = UserRepository.getFirstUser();
  const userId = req.body.userId || defaultUser?.id;

  if (!userId) {
    res.status(400).json({ success: false, error: 'No valid user found' });
    return;
  }

  // Format timeOfDay to HH:MM:SS
  let timeStr = req.body.timeOfDay;
  if (timeStr.length === 5) timeStr += ':00';

  const alarm = AlarmRepository.create({
    ...req.body,
    userId,
    timeOfDay: timeStr
  });

  res.status(201).json({ success: true, alarm });
});

// PUT /api/alarms/:id - Update alarm settings
alarmRouter.put('/:id', (req: Request, res: Response) => {
  const alarmId = String(req.params.id);
  const updated = AlarmRepository.update(alarmId, req.body);
  if (!updated) {
    res.status(404).json({ success: false, error: 'Alarm not found' });
    return;
  }
  res.json({ success: true, alarm: updated });
});

// DELETE /api/alarms/:id - Remove alarm
alarmRouter.delete('/:id', (req: Request, res: Response) => {
  const alarmId = String(req.params.id);
  const success = AlarmRepository.delete(alarmId);
  res.json({ success });
});
