// Database Seed: 10 Starter Task Templates, Starter Tasks & Audio Profiles
import { DatabaseService } from './connection';
import { v4 as uuidv4 } from 'uuid';
import * as crypto from 'crypto';

export const STARTER_TEMPLATES = [
  {
    id: 'tpl-make-bed',
    name: 'Make Your Bed',
    description: 'Smooth sheets flat and align pillows to establish immediate order in your sleeping quarters.',
    instructions: 'Step out of bed completely. Straighten quilt and align pillows flat. Snap a photo of completed bed.',
    category: 'morning',
    proof_type: 'PHOTO',
    default_difficulty: 1,
    base_xp: 50,
    estimated_duration_sec: 60,
    icon_name: 'bed',
    validation_rules: { minLuminance: 30, requiredLabels: ['bed', 'pillow'] }
  },
  {
    id: 'tpl-pushups-10',
    name: '10 Morning Push-Ups',
    description: 'Elevate heart rate and activate neuromuscular systems with 10 strict repetitions.',
    instructions: 'Prop camera 5-6 feet away. Execute 10 chest-to-floor push-ups in under 60 seconds.',
    category: 'physical',
    proof_type: 'VIDEO',
    default_difficulty: 3,
    base_xp: 30,
    estimated_duration_sec: 45,
    icon_name: 'fitness_center',
    validation_rules: { minRepetitions: 10, minDurationSec: 10 }
  },
  {
    id: 'tpl-brush-teeth',
    name: 'Brush Teeth (2 Minutes)',
    description: 'Oral hygiene routine signaling metabolic alertness to your nervous system.',
    instructions: 'Record short 10-15s check-in while brushing teeth thoroughly at the sink.',
    category: 'personal',
    proof_type: 'PHOTO',
    default_difficulty: 1,
    base_xp: 15,
    estimated_duration_sec: 120,
    icon_name: 'clean_hands',
    validation_rules: { minLuminance: 25 }
  },
  {
    id: 'tpl-hydrate-glass',
    name: 'Drink 500ml Water',
    description: 'Rehydrate immediately upon waking to kickstart cellular metabolism.',
    instructions: 'Drink a full glass of water. Take a photo of the empty glass at the counter.',
    category: 'morning',
    proof_type: 'PHOTO',
    default_difficulty: 1,
    base_xp: 40,
    estimated_duration_sec: 30,
    icon_name: 'water_drop',
    validation_rules: { minLuminance: 25 }
  },
  {
    id: 'tpl-morning-sunlight',
    name: 'Morning Sunlight Exposure',
    description: 'Natural outdoor photons into eyes to trigger the cortisol awakening response.',
    instructions: 'Step outside within 3 minutes of waking. Snap a clear photo of the outdoor horizon.',
    category: 'morning',
    proof_type: 'PHOTO',
    default_difficulty: 2,
    base_xp: 75,
    estimated_duration_sec: 180,
    icon_name: 'wb_sunny',
    validation_rules: { minLuminance: 100 }
  },
  {
    id: 'tpl-clean-desk',
    name: 'Clear Workspace',
    description: 'Remove clutter and create an organized surface for focused output.',
    instructions: 'Straighten keyboard and desk surface. Snap an overhead photo.',
    category: 'environment',
    proof_type: 'PHOTO',
    default_difficulty: 1,
    base_xp: 50,
    estimated_duration_sec: 120,
    icon_name: 'table_restaurant',
    validation_rules: { minLuminance: 35 }
  },
  {
    id: 'tpl-walk-2min',
    name: '2-Minute Outdoor Walk',
    description: 'Gentle aerobic locomotion to stimulate lymphatic flow and alertness.',
    instructions: 'Step out the front door and take a brisk 2-minute stride.',
    category: 'physical',
    proof_type: 'PHOTO',
    default_difficulty: 2,
    base_xp: 70,
    estimated_duration_sec: 120,
    icon_name: 'directions_walk',
    validation_rules: { minLuminance: 30 }
  },
  {
    id: 'tpl-read-2pages',
    name: 'Read 2 Physical Pages',
    description: 'Engage cognitive focus on non-screen physical text.',
    instructions: 'Read 2 full physical pages attentively. Take a legible photo of the open book.',
    category: 'mind',
    proof_type: 'PHOTO',
    default_difficulty: 2,
    base_xp: 60,
    estimated_duration_sec: 180,
    icon_name: 'menu_book',
    validation_rules: { minLuminance: 40 }
  },
  {
    id: 'tpl-body-stretch-30s',
    name: '30-Second Full Body Stretch',
    description: 'Decompress spinal column and open thoracic posture.',
    instructions: 'Perform overhead extensions and deep hamstring mobility stretches.',
    category: 'physical',
    proof_type: 'VIDEO',
    default_difficulty: 1,
    base_xp: 50,
    estimated_duration_sec: 30,
    icon_name: 'self_improvement',
    validation_rules: { minDurationSec: 15 }
  },
  {
    id: 'tpl-prep-tomorrow-clothes',
    name: 'Night Prep: Lay Out Tomorrow Gear',
    description: 'Evening friction-reduction ritual for frictionless next-morning execution.',
    instructions: 'Select tomorrow workout clothes and shoes. Lay them out ready.',
    category: 'environment',
    proof_type: 'PHOTO',
    default_difficulty: 1,
    base_xp: 45,
    estimated_duration_sec: 90,
    icon_name: 'checkroom',
    validation_rules: { minLuminance: 25 }
  }
];

import { AuthSecurity } from '../modules/auth/auth.security';

export function hashPassword(password: string): string {
  return crypto.createHash('sha256').update(password).digest('hex');
}

export function seedDatabase(): { defaultUserId: string } {
  const db = DatabaseService.getDb();
  const now = new Date().toISOString();

  // 1. Seed Default User if none exists
  const existingUser = db.prepare('SELECT id FROM users LIMIT 1').get() as { id: string } | undefined;
  let defaultUserId = existingUser?.id;

  if (!defaultUserId) {
    defaultUserId = uuidv4();
    const defaultPasswordHash = hashPassword('Discipline2026!');

    db.prepare(`
      INSERT INTO users (id, email, password_hash, display_name, timezone, discipline_score, autonomy_level, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, 100, 1, ?, ?)
    `).run(defaultUserId, 'alex@habitat.discipline', defaultPasswordHash, 'Alex Mercer', 'America/New_York', now, now);

    db.prepare(`
      INSERT INTO streaks (user_id, current_streak, longest_streak, grace_tokens, updated_at)
      VALUES (?, 1, 1, 1, ?)
    `).run(defaultUserId, now);

    db.prepare(`
      INSERT INTO xp_transactions (id, user_id, amount, reason, created_at)
      VALUES (?, ?, 100, 'NEW_RECRUIT_BONUS', ?)
    `).run(uuidv4(), defaultUserId, now);
  }

  // 2. Seed Task Templates
  const insertTemplate = db.prepare(`
    INSERT OR REPLACE INTO task_templates (id, name, description, instructions, category, proof_type, default_difficulty, base_xp, estimated_duration_sec, icon_name, validation_rules, is_active, sort_order, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
  `);

  let sortOrder = 0;
  for (const tpl of STARTER_TEMPLATES) {
    insertTemplate.run(
      tpl.id,
      tpl.name,
      tpl.description,
      tpl.instructions,
      tpl.category,
      tpl.proof_type,
      tpl.default_difficulty,
      tpl.base_xp,
      tpl.estimated_duration_sec,
      tpl.icon_name,
      JSON.stringify(tpl.validation_rules),
      sortOrder++,
      now
    );
  }

  // 3. Seed Global Starter Tasks (user_id = NULL)
  const insertTask = db.prepare(`
    INSERT OR IGNORE INTO tasks (id, user_id, template_id, slug, title, name, description, instructions, category, proof_type, verification_type, difficulty, base_xp, xp_reward, estimated_duration_sec, icon_name, validation_rules, status, is_active, is_starter, sort_order, created_at)
    VALUES (?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, 'BASIC', ?, ?, ?, ?, ?, ?, 'ACTIVE', 1, 1, ?, ?)
  `);

  let taskOrder = 0;
  for (const tpl of STARTER_TEMPLATES) {
    const slug = tpl.id.replace('tpl-', '');
    const mult = tpl.default_difficulty === 3 ? 1.5 : (tpl.default_difficulty === 2 ? 1.25 : 1.0);
    const xpReward = Math.round(tpl.base_xp * mult);
    const diffVal = tpl.default_difficulty === 3 ? 'HARD' : (tpl.default_difficulty === 2 ? 'MEDIUM' : 'EASY');

    insertTask.run(
      uuidv4(),
      tpl.id,
      slug,
      tpl.name,
      tpl.name,
      tpl.description,
      tpl.instructions,
      tpl.category,
      tpl.proof_type,
      diffVal,
      tpl.base_xp,
      xpReward,
      tpl.estimated_duration_sec,
      tpl.icon_name,
      JSON.stringify(tpl.validation_rules),
      taskOrder++,
      now
    );
  }

  // 4. Seed Starter Challenges
  const insertChallenge = db.prepare(`
    INSERT OR IGNORE INTO challenges (id, title, description, duration_days, reward_xp, trophy_name, task_ids, start_date, end_date, is_active, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
  `);

  insertChallenge.run(
    'challenge-14-order',
    '14-Day Morning Order Tournament',
    'Execute your morning bed and sunlight missions for 14 consecutive days without missing a beat.',
    14,
    500,
    'Morning Sovereign Trophy',
    JSON.stringify(['make-bed', 'morning-sunlight']),
    now.substring(0, 10),
    '2026-12-31',
    now
  );

  // 5. Seed Psychoacoustic Sound Profiles
  const insertAudio = db.prepare(`
    INSERT OR IGNORE INTO audio_profiles (id, user_id, name, base_frequency_hz, binaural_beat_hz, escalation_profile, strobe_interval_ms, is_preset, created_at)
    VALUES (?, NULL, ?, ?, ?, ?, ?, 1, ?)
  `);

  insertAudio.run('audio-spartan', 'Spartan War Siren', 880, 40.0, 'EXPONENTIAL', 200, now);
  insertAudio.run('audio-gamma', 'Gamma 40Hz Prefrontal Ignition', 432, 40.0, 'STROBE_PULSE', 150, now);
  insertAudio.run('audio-shockwave', 'Sub-Bass Kinetic Shockwave', 120, 25.0, 'EXPONENTIAL', 300, now);

  // 6. Seed Default Active Alarms & Hydration for Recruit (Runtime only, preserving clean state in unit tests)
  if (defaultUserId && process.env.NODE_ENV !== 'test') {
    const bedTask = db.prepare("SELECT id FROM tasks WHERE slug = 'make-bed' LIMIT 1").get() as { id: string } | undefined;
    const pushupTask = db.prepare("SELECT id FROM tasks WHERE slug = 'pushups-10' LIMIT 1").get() as { id: string } | undefined;

    const insertAlarm = db.prepare(`
      INSERT OR IGNORE INTO alarms (id, user_id, task_id, time_of_day, timezone, repeat_days, discipline_mode, retry_interval_minutes, is_enabled, created_at, updated_at)
      VALUES (?, ?, ?, ?, 'America/New_York', '[1,2,3,4,5]', 'DISCIPLINE', 5, 1, ?, ?)
    `);

    if (pushupTask) {
      insertAlarm.run('alarm-morning-pushup', defaultUserId, pushupTask.id, '06:30:00', now, now);
    }
    if (bedTask) {
      insertAlarm.run('alarm-morning-bed', defaultUserId, bedTask.id, '07:00:00', now, now);
    }

    // Seed Initial Morning Hydration
    db.prepare(`
      INSERT OR IGNORE INTO hydration_entries (id, user_id, amount_ml, timestamp, source, created_at)
      VALUES (?, ?, 500, ?, 'APP', ?)
    `).run('hydration-morning-water', defaultUserId, now, now);
  }

  // 7. Seed Initial Welcome Journal Entry
  if (defaultUserId) {
    db.prepare(`
      INSERT OR IGNORE INTO journal_entries (id, user_id, title, content, rating, tags, created_at, updated_at)
      VALUES (?, ?, 'Day 1: The Contract', 'Commitment established. Morning inertia will be confronted with physical action. No snooze button. No excuses.', 5, '["discipline","day1"]', ?, ?)
    `).run('journal-welcome-entry', defaultUserId, now, now);
  }

  return { defaultUserId };
}
