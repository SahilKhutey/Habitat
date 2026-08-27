// Task Repository
import { DatabaseService } from '../connection';
import { Task } from '../../domain/types';
import { v4 as uuidv4 } from 'uuid';

export class TaskRepository {
  public static getAll(): Task[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM tasks ORDER BY is_starter DESC, title ASC').all() as any[];
    return rows.map(this.mapToTask);
  }

  public static getById(id: string): Task | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM tasks WHERE id = ?').get(id) as any;
    if (!row) return null;
    return this.mapToTask(row);
  }

  public static getBySlug(slug: string): Task | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM tasks WHERE slug = ?').get(slug) as any;
    if (!row) return null;
    return this.mapToTask(row);
  }

  public static create(task: Omit<Task, 'id' | 'createdAt'>): Task {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    const stmt = db.prepare(`
      INSERT INTO tasks (id, slug, title, description, category, proof_type, verification_level, base_xp, instructions, validation_rules, is_starter, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      id,
      task.slug,
      task.title,
      task.description,
      task.category,
      task.proofType,
      task.verificationLevel,
      task.baseXp,
      JSON.stringify(task.instructions),
      JSON.stringify(task.validationRules),
      task.isStarter ? 1 : 0,
      now
    );

    return {
      ...task,
      id,
      createdAt: now
    };
  }

  private static mapToTask(row: any): Task {
    return {
      id: row.id,
      slug: row.slug,
      title: row.title,
      description: row.description,
      category: row.category,
      proofType: row.proof_type,
      verificationLevel: row.verification_level,
      baseXp: row.base_xp,
      instructions: JSON.parse(row.instructions || '[]'),
      validationRules: JSON.parse(row.validation_rules || '{}'),
      isStarter: Boolean(row.is_starter),
      createdAt: row.created_at
    };
  }
}
