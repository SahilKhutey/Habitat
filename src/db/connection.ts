// Database Connection using Node.js Native SQLite (node:sqlite)
import { DatabaseSync } from 'node:sqlite';
import * as path from 'path';
import * as fs from 'fs';

const DB_DIR = path.resolve(process.cwd(), 'data');
if (!fs.existsSync(DB_DIR)) {
  fs.mkdirSync(DB_DIR, { recursive: true });
}

const DB_PATH = process.env.NODE_ENV === 'test' 
  ? ':memory:' 
  : path.join(DB_DIR, 'habitat.db');

export class DatabaseService {
  private static instance: DatabaseSync | null = null;

  public static getDb(): DatabaseSync {
    if (!this.instance) {
      this.instance = new DatabaseSync(DB_PATH);
      // Enable WAL mode & foreign keys for concurrency and integrity
      if (DB_PATH !== ':memory:') {
        this.instance.exec('PRAGMA journal_mode = WAL;');
      }
      this.instance.exec('PRAGMA foreign_keys = ON;');
      this.initializeSchema();
    }
    return this.instance;
  }

  public static resetDbForTesting(): DatabaseSync {
    if (this.instance) {
      this.instance.close();
    }
    this.instance = new DatabaseSync(':memory:');
    this.instance.exec('PRAGMA foreign_keys = ON;');
    this.initializeSchema();
    return this.instance;
  }

  private static initializeSchema(): void {
    if (!this.instance) return;

    const schema = `
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        display_name TEXT NOT NULL,
        timezone TEXT NOT NULL DEFAULT 'UTC',
        discipline_score INTEGER DEFAULT 100,
        autonomy_level INTEGER DEFAULT 1,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        total_xp INTEGER DEFAULT 0,
        grace_tokens INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS tasks (
        id TEXT PRIMARY KEY,
        slug TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        proof_type TEXT NOT NULL,
        verification_level TEXT NOT NULL DEFAULT 'HEURISTIC',
        base_xp INTEGER NOT NULL DEFAULT 50,
        instructions TEXT NOT NULL, -- JSON array of steps
        validation_rules TEXT NOT NULL, -- JSON object
        is_starter INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS alarms (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        task_id TEXT NOT NULL,
        time_of_day TEXT NOT NULL,
        repeat_days TEXT NOT NULL, -- JSON array of integers [0,1,2,3,4,5,6]
        discipline_mode TEXT NOT NULL DEFAULT 'DISCIPLINE',
        retry_interval_minutes INTEGER DEFAULT 5,
        escalation_enabled INTEGER DEFAULT 1,
        sound_pack TEXT DEFAULT 'TACTICAL_SIREN',
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS missions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        alarm_id TEXT,
        task_id TEXT NOT NULL,
        scheduled_for TEXT NOT NULL,
        triggered_at TEXT,
        completed_at TEXT,
        status TEXT NOT NULL DEFAULT 'SCHEDULED',
        attempts_count INTEGER DEFAULT 0,
        resistance_seconds INTEGER,
        xp_awarded INTEGER DEFAULT 0,
        discipline_mode TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (alarm_id) REFERENCES alarms(id) ON DELETE SET NULL,
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS mission_attempts (
        id TEXT PRIMARY KEY,
        mission_id TEXT NOT NULL,
        attempt_index INTEGER NOT NULL,
        triggered_at TEXT NOT NULL,
        resolved_at TEXT,
        status TEXT NOT NULL DEFAULT 'IGNORED',
        siren_volume_level INTEGER DEFAULT 70,
        FOREIGN KEY (mission_id) REFERENCES missions(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS proof_assets (
        id TEXT PRIMARY KEY,
        mission_id TEXT NOT NULL,
        media_type TEXT NOT NULL,
        storage_url TEXT NOT NULL,
        thumbnail_url TEXT,
        captured_at TEXT NOT NULL,
        device_metadata TEXT NOT NULL, -- JSON
        verification_status TEXT NOT NULL DEFAULT 'PENDING',
        ai_confidence_score REAL,
        rejection_reason TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (mission_id) REFERENCES missions(id) ON DELETE CASCADE
      );

      CREATE INDEX IF NOT EXISTS idx_missions_user ON missions(user_id, status);
      CREATE INDEX IF NOT EXISTS idx_alarms_user ON alarms(user_id, is_active);
      CREATE INDEX IF NOT EXISTS idx_missions_scheduled ON missions(scheduled_for);
    `;

    this.instance.exec(schema);
  }
}
