// Stoic Journal & Reflection Service & Controller
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';

export interface JournalEntry {
  id: string;
  userId: string;
  title: string;
  content: string;
  rating: number;
  tags: string[];
  createdAt: string;
  updatedAt: string;
}

export class JournalService {
  public static getAll(userId?: string): JournalEntry[] {
    const db = DatabaseService.getDb();
    let query = 'SELECT * FROM journal_entries';
    const params: any[] = [];
    if (userId) {
      query += ' WHERE user_id = ?';
      params.push(userId);
    }
    query += ' ORDER BY created_at DESC LIMIT 50';

    const rows = db.prepare(query).all(...params) as any[];
    return rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      title: r.title || 'Daily Reflection',
      content: r.content,
      rating: r.rating || 5,
      tags: JSON.parse(r.tags || '[]'),
      createdAt: r.created_at,
      updatedAt: r.updated_at
    }));
  }

  public static getById(id: string): JournalEntry | null {
    const db = DatabaseService.getDb();
    const r = db.prepare('SELECT * FROM journal_entries WHERE id = ?').get(id) as any;
    if (!r) return null;
    return {
      id: r.id,
      userId: r.user_id,
      title: r.title || 'Daily Reflection',
      content: r.content,
      rating: r.rating || 5,
      tags: JSON.parse(r.tags || '[]'),
      createdAt: r.created_at,
      updatedAt: r.updated_at
    };
  }

  public static create(params: {
    userId: string;
    title?: string;
    content: string;
    rating?: number;
    tags?: string[];
  }): JournalEntry {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();
    const rating = Math.max(1, Math.min(5, params.rating ?? 5));
    const title = params.title?.trim() || 'Daily Reflection';
    const tags = JSON.stringify(params.tags || ['reflection', 'stoic']);

    db.prepare(`
      INSERT INTO journal_entries (id, user_id, title, content, rating, tags, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).run(id, params.userId, title, params.content.trim(), rating, tags, now, now);

    return {
      id,
      userId: params.userId,
      title,
      content: params.content.trim(),
      rating,
      tags: params.tags || ['reflection', 'stoic'],
      createdAt: now,
      updatedAt: now
    };
  }

  public static delete(id: string, userId?: string): boolean {
    const db = DatabaseService.getDb();
    let query = 'DELETE FROM journal_entries WHERE id = ?';
    const params: any[] = [id];
    if (userId) {
      query += ' AND user_id = ?';
      params.push(userId);
    }
    db.prepare(query).run(...params);
    return true;
  }
}

export const journalController = Router();

// GET /api/v1/journal - List all journal entries
journalController.get('/', (req: Request, res: Response) => {
  const db = DatabaseService.getDb();
  const defaultUser = db.prepare('SELECT id FROM users LIMIT 1').get() as any;
  const userId = (req.query.userId as string) || (req as any).user?.userId || defaultUser?.id;
  const entries = JournalService.getAll(userId);
  res.json({ success: true, count: entries.length, data: entries });
});

// POST /api/v1/journal - Create reflection entry
journalController.post('/', (req: Request, res: Response) => {
  try {
    const db = DatabaseService.getDb();
    const defaultUser = db.prepare('SELECT id FROM users LIMIT 1').get() as any;
    const userId = req.body.userId || (req as any).user?.userId || defaultUser?.id;
    const { title, content, rating, tags } = req.body;

    if (!content || content.trim().length === 0) {
      res.status(400).json({ success: false, error: 'Content is required for journal reflection' });
      return;
    }

    const entry = JournalService.create({
      userId,
      title,
      content,
      rating,
      tags
    });

    res.status(201).json({ success: true, data: entry });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// DELETE /api/v1/journal/:id - Delete reflection entry
journalController.delete('/:id', (req: Request, res: Response) => {
  try {
    const db = DatabaseService.getDb();
    const defaultUser = db.prepare('SELECT id FROM users LIMIT 1').get() as any;
    const userId = (req.query.userId as string) || (req as any).user?.userId || defaultUser?.id;
    JournalService.delete(String(req.params.id), userId);
    res.json({ success: true, message: 'Journal entry removed' });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});
