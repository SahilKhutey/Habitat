// Task & Discipline Engine Controller (Templates, User Tasks, Lifecycle State Machine & Server XP)
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { authGuard, AuthenticatedRequest } from '../../common/guards/auth.guard';
import { XpCalculator } from './domain/xp-calculator';
import { v4 as uuidv4 } from 'uuid';

export class TasksService {
  // 1. Template Operations
  public static getTemplates() {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM task_templates WHERE is_active = 1 ORDER BY sort_order ASC').all() as any[];

    return rows.map((r) => ({
      id: r.id,
      name: r.name,
      description: r.description,
      instructions: r.instructions,
      category: r.category,
      proofType: r.proof_type,
      defaultDifficulty: r.default_difficulty,
      baseXp: r.base_xp,
      estimatedDurationSec: r.estimated_duration_sec,
      iconName: r.icon_name,
      validationRules: JSON.parse(r.validation_rules || '{}')
    }));
  }

  public static getTemplateById(id: string) {
    const db = DatabaseService.getDb();
    const r = db.prepare('SELECT * FROM task_templates WHERE id = ? AND is_active = 1').get(id) as any;
    if (!r) throw new Error('Template not found or inactive.');

    return {
      id: r.id,
      name: r.name,
      description: r.description,
      instructions: r.instructions,
      category: r.category,
      proofType: r.proof_type,
      defaultDifficulty: r.default_difficulty,
      baseXp: r.base_xp,
      estimatedDurationSec: r.estimated_duration_sec,
      iconName: r.icon_name,
      validationRules: JSON.parse(r.validation_rules || '{}')
    };
  }

  public static createTaskFromTemplate(userId: string, params: {
    templateId: string;
    customName?: string;
    customInstructions?: string;
    difficulty?: number;
    proofType?: string;
  }) {
    const template = this.getTemplateById(params.templateId);
    const difficulty = params.difficulty ?? template.defaultDifficulty;
    const numDiff = typeof difficulty === 'string'
      ? (difficulty === 'HARD' ? 3 : (difficulty === 'EASY' ? 1 : 2))
      : difficulty;
    const xpReward = XpCalculator.calculateXp(template.baseXp, numDiff);

    const id = uuidv4();
    const now = new Date().toISOString();
    const slug = `${template.id.replace('tpl-', '')}-${userId ? userId.substring(0, 8) : 'anon'}-${uuidv4().substring(0, 8)}`;
    const db = DatabaseService.getDb();

    db.prepare(`
      INSERT INTO tasks (id, user_id, template_id, slug, title, name, description, instructions, category, proof_type, difficulty, base_xp, xp_reward, estimated_duration_sec, icon_name, validation_rules, status, is_active, is_starter, sort_order, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE', 1, 0, 0, ?)
    `).run(
      id,
      userId,
      template.id,
      slug,
      params.customName || template.name,
      params.customName || template.name,
      template.description,
      params.customInstructions || template.instructions,
      template.category,
      params.proofType || template.proofType,
      difficulty,
      template.baseXp,
      xpReward,
      template.estimatedDurationSec,
      template.iconName,
      JSON.stringify(template.validationRules),
      now
    );

    return this.getTaskById(id, userId);
  }

  // 2. User Task Operations
  public static getUserTasks(userId: string, filters: {
    status?: string;
    category?: string;
    proofType?: string;
    search?: string;
    page?: number;
    limit?: number;
  }) {
    const db = DatabaseService.getDb();
    const limit = Math.min(50, filters.limit || 20);
    const offset = ((filters.page || 1) - 1) * limit;

    let query = userId ? 'SELECT * FROM tasks WHERE (user_id = ? OR user_id IS NULL)' : 'SELECT * FROM tasks WHERE 1=1';
    const params: any[] = userId ? [userId] : [];

    if (filters.status && filters.status !== 'ALL') {
      query += ' AND status = ?';
      params.push(filters.status);
    } else {
      query += " AND status != 'ARCHIVED'";
    }

    if (filters.category) {
      query += ' AND LOWER(category) = ?';
      params.push(filters.category.toLowerCase());
    }

    if (filters.proofType) {
      query += ' AND LOWER(proof_type) = ?';
      params.push(filters.proofType.toLowerCase());
    }

    if (filters.search) {
      query += ' AND (title LIKE ? OR description LIKE ? OR name LIKE ?)';
      params.push(`%${filters.search}%`, `%${filters.search}%`, `%${filters.search}%`);
    }

    query += ' ORDER BY sort_order ASC, created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);

    const rows = db.prepare(query).all(...params) as any[];

    return rows.map((r) => this.mapTask(r));
  }

  public static getTaskById(taskId: string, userId?: string) {
    const db = DatabaseService.getDb();
    let query = 'SELECT * FROM tasks WHERE id = ?';
    const params: any[] = [taskId];

    if (userId) {
      query += ' AND (user_id = ? OR user_id IS NULL)';
      params.push(userId);
    }

    const row = db.prepare(query).get(...params) as any;
    if (!row) throw new Error('Task not found or access unauthorized.');

    return this.mapTask(row);
  }

  public static createCustomTask(
    userIdOrParams: string | any,
    maybeParams?: any
  ) {
    let userId: string;
    let name: string;
    let description: string = '';
    let instructions: any;
    let category: string;
    let proofType: string;
    let difficulty: any;
    let baseXp: number;
    let estimatedDurationSec: number;
    let validationRules: any;

    if (typeof userIdOrParams === 'object') {
      userId = userIdOrParams.userId;
      name = userIdOrParams.name || userIdOrParams.title;
      description = userIdOrParams.description || '';
      instructions = userIdOrParams.instructions;
      category = userIdOrParams.category || 'CUSTOM';
      proofType = userIdOrParams.proofType || 'PHOTO';
      difficulty = userIdOrParams.difficulty !== undefined ? userIdOrParams.difficulty : 2;
      baseXp = userIdOrParams.baseXp || 25;
      estimatedDurationSec = userIdOrParams.estimatedDurationSec || 60;
      validationRules = userIdOrParams.validationRules || {};
    } else {
      userId = userIdOrParams;
      name = maybeParams.name || maybeParams.title;
      description = maybeParams.description || '';
      instructions = maybeParams.instructions;
      category = maybeParams.category || 'CUSTOM';
      proofType = maybeParams.proofType || 'PHOTO';
      difficulty = maybeParams.difficulty !== undefined ? maybeParams.difficulty : 2;
      baseXp = maybeParams.baseXp || 25;
      estimatedDurationSec = maybeParams.estimatedDurationSec || 60;
      validationRules = maybeParams.validationRules || {};
    }

    if (!name || name.trim().length < 2) {
      throw new Error('Task name must be at least 2 characters long.');
    }

    const numDiff = typeof difficulty === 'string'
      ? (difficulty === 'HARD' ? 3 : (difficulty === 'EASY' ? 1 : 2))
      : Math.max(1, Math.min(5, difficulty || 2));

    const xpReward = XpCalculator.calculateXp(baseXp, numDiff);

    const id = uuidv4();
    const now = new Date().toISOString();
    const slug = `custom-${userId ? userId.substring(0, 8) : 'anon'}-${uuidv4().substring(0, 8)}`;
    const db = DatabaseService.getDb();

    const formattedInstructions = Array.isArray(instructions)
      ? JSON.stringify(instructions)
      : (typeof instructions === 'string' ? instructions : '');

    db.prepare(`
      INSERT INTO tasks (id, user_id, template_id, slug, title, name, description, instructions, category, proof_type, difficulty, base_xp, xp_reward, estimated_duration_sec, icon_name, validation_rules, status, is_active, is_starter, sort_order, created_at)
      VALUES (?, ?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'bolt', ?, 'ACTIVE', 1, 0, 0, ?)
    `).run(
      id,
      userId || null,
      slug,
      name.trim(),
      name.trim(),
      description,
      formattedInstructions,
      category.toLowerCase(),
      proofType.toUpperCase(),
      difficulty,
      baseXp,
      xpReward,
      estimatedDurationSec,
      JSON.stringify(validationRules),
      now
    );

    return this.getTaskById(id, userId);
  }

  public static updateTask(taskId: string, userId: string, params: {
    name?: string;
    description?: string;
    instructions?: string;
    difficulty?: number | string;
    proofType?: string;
  }) {
    const task = this.getTaskById(taskId, userId);
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();

    let newXpReward = task.xpReward;
    if (params.difficulty !== undefined) {
      const numDiff = typeof params.difficulty === 'string'
        ? (params.difficulty === 'HARD' ? 3 : (params.difficulty === 'EASY' ? 1 : 2))
        : params.difficulty;
      newXpReward = XpCalculator.calculateXp(task.baseXp, numDiff);
    }

    db.prepare(`
      UPDATE tasks
      SET title = COALESCE(?, title),
          name = COALESCE(?, name),
          description = COALESCE(?, description),
          instructions = COALESCE(?, instructions),
          difficulty = COALESCE(?, difficulty),
          proof_type = COALESCE(?, proof_type),
          xp_reward = COALESCE(?, xp_reward),
          updated_at = ?
      WHERE id = ? AND user_id = ?
    `).run(
      params.name || null,
      params.name || null,
      params.description || null,
      params.instructions || null,
      params.difficulty ?? null,
      params.proofType || null,
      newXpReward,
      now,
      taskId,
      userId
    );

    return this.getTaskById(taskId, userId);
  }

  public static setTaskStatus(taskId: string, userId: string, status: 'ACTIVE' | 'PAUSED' | 'ARCHIVED') {
    const task = this.getTaskById(taskId, userId);
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();

    db.prepare(`
      UPDATE tasks 
      SET status = ?, 
          is_active = ?, 
          archived_at = ?,
          updated_at = ?
      WHERE id = ? AND user_id = ?
    `).run(
      status,
      status === 'ACTIVE' ? 1 : 0,
      status === 'ARCHIVED' ? now : null,
      now,
      taskId,
      userId
    );

    return this.getTaskById(taskId, userId);
  }

  public static duplicateTask(taskId: string, userId: string) {
    const task = this.getTaskById(taskId, userId);
    return this.createCustomTask(userId, {
      name: `${task.name} (Copy)`,
      description: task.description,
      instructions: task.instructions,
      category: task.category,
      proofType: task.proofType,
      difficulty: task.difficultyLevel || 2,
      baseXp: task.baseXp,
      estimatedDurationSec: task.estimatedDurationSec,
      validationRules: task.validationRules
    });
  }

  public static reorderTasks(userId: string, items: { id: string; position: number }[]) {
    const db = DatabaseService.getDb();
    const updateStmt = db.prepare('UPDATE tasks SET sort_order = ? WHERE id = ? AND user_id = ?');

    for (const item of items) {
      updateStmt.run(item.position, item.id, userId);
    }

    return this.getUserTasks(userId, { status: 'ALL' });
  }

  public static deleteCustomTask(taskId: string, userId: string): boolean {
    const db = DatabaseService.getDb();
    const task = db.prepare('SELECT * FROM tasks WHERE id = ?').get(taskId) as any;
    if (!task) return false;

    if (task.is_starter === 1 || !task.user_id) {
      throw new Error('Cannot delete system starter tasks.');
    }

    if (task.user_id !== userId) {
      throw new Error('Unauthorized');
    }

    db.prepare('DELETE FROM tasks WHERE id = ?').run(taskId);
    return true;
  }

  public static getCategories(userId?: string) {
    const db = DatabaseService.getDb();
    let query = `
      SELECT category, COUNT(*) as count 
      FROM tasks 
      WHERE status != 'ARCHIVED'
    `;
    const params: any[] = [];
    if (userId) {
      query += ' AND (user_id = ? OR user_id IS NULL)';
      params.push(userId);
    }
    query += ' GROUP BY category';

    const rows = db.prepare(query).all(...params) as any[];

    const categoryLabels: Record<string, string> = {
      morning: 'Morning Order',
      physical: 'Physical Training',
      personal: 'Personal Hygiene',
      environment: 'Environment',
      mind: 'Mind & Study',
      study: 'Mind & Study',
      health: 'Health & Hydration',
      custom: 'Custom'
    };

    return rows.map((r) => ({
      category: r.category.toLowerCase(),
      label: categoryLabels[r.category.toLowerCase()] || r.category,
      count: r.count
    }));
  }

  public static getById(taskId: string) {
    try {
      return this.getTaskById(taskId);
    } catch {
      return null;
    }
  }

  public static getAll(filters?: any) {
    const db = DatabaseService.getDb();
    let query = 'SELECT * FROM tasks WHERE 1=1';
    const params: any[] = [];

    if (filters?.userId) {
      query += ' AND (user_id = ? OR user_id IS NULL)';
      params.push(filters.userId);
    }
    if (filters?.category) {
      query += ' AND LOWER(category) = ?';
      params.push(filters.category.toLowerCase());
    }
    if (filters?.difficulty) {
      const diffVal = filters.difficulty === 'HARD' ? 3 : (filters.difficulty === 'EASY' ? 1 : 2);
      query += ' AND (difficulty = ? OR difficulty = ?)';
      params.push(diffVal, filters.difficulty);
    }
    query += ' ORDER BY created_at ASC';

    const rows = db.prepare(query).all(...params) as any[];
    return rows.map((r) => this.mapTask(r));
  }

  private static mapTask(r: any) {
    let parsedInstructions: any = r.instructions;
    try {
      if (r.instructions && typeof r.instructions === 'string' && r.instructions.startsWith('[')) {
        parsedInstructions = JSON.parse(r.instructions);
      }
    } catch {
      // keep raw string
    }

    const rawDiff = r.difficulty;
    let numDiff = 2;
    if (typeof rawDiff === 'number') {
      numDiff = rawDiff;
    } else if (rawDiff === 'HARD') {
      numDiff = 3;
    } else if (rawDiff === 'EASY') {
      numDiff = 1;
    }

    return {
      id: r.id,
      userId: r.user_id,
      templateId: r.template_id,
      slug: r.slug,
      title: r.title || r.name,
      name: r.name || r.title,
      description: r.description,
      instructions: parsedInstructions,
      category: (r.category || 'morning').toLowerCase(),
      proofType: r.proof_type,
      difficulty: rawDiff,
      difficultyLevel: numDiff,
      baseXp: r.base_xp,
      xpReward: r.xp_reward || r.base_xp,
      estimatedDurationSec: r.estimated_duration_sec,
      iconName: r.icon_name,
      validationRules: JSON.parse(r.validation_rules || '{}'),
      status: r.status || (r.is_active ? 'ACTIVE' : 'PAUSED'),
      isActive: Boolean(r.is_active),
      isStarter: Boolean(r.is_starter),
      sortOrder: r.sort_order || 0,
      createdAt: r.created_at,
      updatedAt: r.updated_at,
      archivedAt: r.archived_at
    };
  }
}

export const tasksController = Router();

// GET /api/v1/tasks/templates
tasksController.get('/templates', (req: Request, res: Response) => {
  const templates = TasksService.getTemplates();
  res.json({ success: true, count: templates.length, data: templates });
});

// GET /api/v1/tasks/templates/:id
tasksController.get('/templates/:id', (req: Request, res: Response) => {
  try {
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const template = TasksService.getTemplateById(id);
    res.json({ success: true, data: template });
  } catch (err: any) {
    res.status(404).json({ success: false, error: { message: err.message } });
  }
});

// POST /api/v1/tasks/from-template
tasksController.post('/from-template', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const task = TasksService.createTaskFromTemplate(req.user!.userId, req.body);
    res.status(201).json({ success: true, data: task });
  } catch (err: any) {
    res.status(400).json({ success: false, error: { message: err.message } });
  }
});

// GET /api/v1/tasks
tasksController.get('/', (req: Request, res: Response) => {
  const db = DatabaseService.getDb();
  const defaultUser = db.prepare('SELECT id FROM users LIMIT 1').get() as any;
  const userId = (req.query.userId as string) || defaultUser?.id;

  const tasks = TasksService.getUserTasks(userId, {
    status: req.query.status as string,
    category: req.query.category as string,
    proofType: req.query.proofType as string,
    search: req.query.search as string,
    page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
    limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20
  });

  res.json({ success: true, count: tasks.length, data: tasks });
});

// POST /api/v1/tasks
tasksController.post('/', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const task = TasksService.createCustomTask(req.user!.userId, req.body);
    res.status(201).json({ success: true, data: task });
  } catch (err: any) {
    res.status(400).json({ success: false, error: { message: err.message } });
  }
});

// GET /api/v1/tasks/:id
tasksController.get('/:id', (req: Request, res: Response) => {
  try {
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const task = TasksService.getTaskById(id);
    res.json({ success: true, data: task });
  } catch (err: any) {
    res.status(404).json({ success: false, error: { message: err.message } });
  }
});

// PATCH /api/v1/tasks/:id
tasksController.patch('/:id', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const task = TasksService.updateTask(id, req.user!.userId, req.body);
    res.json({ success: true, data: task });
  } catch (err: any) {
    res.status(400).json({ success: false, error: { message: err.message } });
  }
});

// POST /api/v1/tasks/:id/pause
tasksController.post('/:id/pause', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const task = TasksService.setTaskStatus(id, req.user!.userId, 'PAUSED');
    res.json({ success: true, data: task });
  } catch (err: any) {
    res.status(400).json({ success: false, error: { message: err.message } });
  }
});

// POST /api/v1/tasks/:id/resume
tasksController.post('/:id/resume', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const task = TasksService.setTaskStatus(id, req.user!.userId, 'ACTIVE');
    res.json({ success: true, data: task });
  } catch (err: any) {
    res.status(400).json({ success: false, error: { message: err.message } });
  }
});

// POST /api/v1/tasks/:id/archive
tasksController.post('/:id/archive', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const task = TasksService.setTaskStatus(id, req.user!.userId, 'ARCHIVED');
    res.json({ success: true, data: task });
  } catch (err: any) {
    res.status(400).json({ success: false, error: { message: err.message } });
  }
});

// POST /api/v1/tasks/:id/duplicate
tasksController.post('/:id/duplicate', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const task = TasksService.duplicateTask(id, req.user!.userId);
    res.status(201).json({ success: true, data: task });
  } catch (err: any) {
    res.status(400).json({ success: false, error: { message: err.message } });
  }
});

// PATCH /api/v1/tasks/reorder
tasksController.patch('/reorder', authGuard, (req: AuthenticatedRequest, res: Response) => {
  try {
    const { items } = req.body;
    const tasks = TasksService.reorderTasks(req.user!.userId, items || []);
    res.json({ success: true, data: tasks });
  } catch (err: any) {
    res.status(400).json({ success: false, error: { message: err.message } });
  }
});
