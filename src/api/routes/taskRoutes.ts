// Tasks REST Routes
import { Router, Request, Response } from 'express';
import { TaskRepository } from '../../db/repositories/taskRepository';
import { z } from 'zod';
import { validate } from '../middleware/validate';

export const taskRouter = Router();

// GET /api/tasks - Retrieve all starter & custom tasks
taskRouter.get('/', (req: Request, res: Response) => {
  const tasks = TaskRepository.getAll();
  res.json({ success: true, count: tasks.length, tasks });
});

// GET /api/tasks/:id - Retrieve specific task
taskRouter.get('/:id', (req: Request, res: Response) => {
  const taskId = String(req.params.id);
  const task = TaskRepository.getById(taskId);
  if (!task) {
    res.status(404).json({ success: false, error: 'Task not found' });
    return;
  }
  res.json({ success: true, task });
});

const createTaskSchema = z.object({
  slug: z.string().min(2),
  title: z.string().min(3),
  description: z.string().min(5),
  category: z.enum(['exercise', 'hygiene', 'environment', 'health', 'mindset', 'routine']),
  proofType: z.enum(['PHOTO', 'VIDEO', 'SENSOR']),
  verificationLevel: z.enum(['HEURISTIC', 'SMART_CV', 'AI_ACTION']).default('HEURISTIC'),
  baseXp: z.number().int().min(10).max(500).default(50),
  instructions: z.array(z.string()).min(1),
  validationRules: z.record(z.any()).default({}),
  isStarter: z.boolean().default(false)
});

// POST /api/tasks - Create custom task
taskRouter.post('/', validate(createTaskSchema), (req: Request, res: Response) => {
  const newTask = TaskRepository.create(req.body);
  res.status(201).json({ success: true, task: newTask });
});
