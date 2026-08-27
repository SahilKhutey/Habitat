// Clean Architecture Task Repository
import { DatabaseService } from '../db/connection';
import { v4 as uuidv4 } from 'uuid';

export interface TaskEntity {
  id: string;
  userId: string | null;
  slug: string;
  title: string;
  description: string;
  category: string;
  difficulty: string;
  proofType: string;
  verificationType: string;
  baseXp: number;
  estimatedDurationSec: number;
  iconName: string;
  instructions: string;
  validationRules: Record<string, any>;
  isStarter: boolean;
  createdAt: string;
}

export class TaskRepository {
  public static findById(id: string): TaskEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM tasks WHERE id = ?').get(id) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public static findBySlug(slug: string): TaskEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM tasks WHERE slug = ?').get(slug) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public static findAll(): TaskEntity[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM tasks ORDER BY created_at ASC').all() as any[];
    return rows.map(this.mapRow);
  }

  public static create(params: {
    userId?: string;
    slug: string;
    title: string;
    description: string;
    category: string;
    difficulty?: 'EASY' | 'MEDIUM' | 'HARD';
    proofType: 'PHOTO' | 'VIDEO' | 'HARDWARE_ANCHOR';
    verificationType?: 'BASIC' | 'SMART_CV' | 'AI_POSE_REP_COUNTER' | 'HARDWARE_TOKEN';
    baseXp?: number;
    estimatedDurationSec?: number;
    iconName?: string;
    instructions?: string;
    validationRules?: Record<string, any>;
    isStarter?: boolean;
  }): TaskEntity {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO tasks (id, user_id, slug, title, description, category, difficulty, proof_type, verification_type, base_xp, estimated_duration_sec, icon_name, instructions, validation_rules, is_starter, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      id,
      params.userId || null,
      params.slug,
      params.title,
      params.description,
      params.category,
      params.difficulty || 'MEDIUM',
      params.proofType,
      params.verificationType || 'BASIC',
      params.baseXp || 50,
      params.estimatedDurationSec || 60,
      params.iconName || 'hotel',
      params.instructions || 'Execute required actions.',
      JSON.stringify(params.validationRules || {}),
      params.isStarter ? 1 : 0,
      now
    );

    return this.findById(id)!;
  }

  public static getUserTasks(userId: string): TaskEntity[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare(`
      SELECT * FROM tasks 
      WHERE user_id = ? OR user_id IS NULL 
      ORDER BY is_starter DESC, created_at ASC
    `).all(userId) as any[];

    return rows.map(this.mapRow);
  }

  private static mapRow(row: any): TaskEntity {
    return {
      id: row.id,
      userId: row.user_id,
      slug: row.slug,
      title: row.title,
      description: row.description,
      category: row.category,
      difficulty: row.difficulty,
      proofType: row.proof_type,
      verificationType: row.verification_type,
      baseXp: row.base_xp,
      estimatedDurationSec: row.estimated_duration_sec,
      iconName: row.icon_name,
      instructions: row.instructions,
      validationRules: JSON.parse(row.validation_rules || '{}'),
      isStarter: Boolean(row.is_starter),
      createdAt: row.created_at
    };
  }
}
