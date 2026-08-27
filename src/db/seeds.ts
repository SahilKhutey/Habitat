// Seed Starter Tasks and Default Profile
import { DatabaseService } from './connection';
import { v4 as uuidv4 } from 'uuid';

export const STARTER_TASKS = [
  {
    slug: 'make-bed',
    title: 'Make Your Bed',
    description: 'Physically organize and smooth your sleeping quarters to establish immediate morning order.',
    category: 'environment',
    proof_type: 'PHOTO',
    verification_level: 'HEURISTIC',
    base_xp: 50,
    instructions: [
      'Step out of bed completely',
      'Smooth sheets and straighten quilt flat',
      'Align pillows at headboard',
      'Take a clear, well-lit photo of the completed bed'
    ],
    validation_rules: { minLuminance: 30, requiredLabels: ['bed', 'pillow'] }
  },
  {
    slug: 'pushups-10',
    title: '10 Morning Push-Ups',
    description: 'Elevate heart rate and activate neuromuscular systems with 10 full repetitions.',
    category: 'exercise',
    proof_type: 'VIDEO',
    verification_level: 'SMART_CV',
    base_xp: 80,
    instructions: [
      'Prop phone up 5-6 feet away in clear view',
      'Assume full plank position',
      'Complete 10 strict chest-to-floor push-ups',
      'Submit the recorded video clip'
    ],
    validation_rules: { minDurationSec: 10, motionThreshold: 0.6 }
  },
  {
    slug: 'brush-teeth',
    title: 'Brush Teeth',
    description: 'Oral hygiene routine to signal alertness to your nervous system.',
    category: 'hygiene',
    proof_type: 'VIDEO',
    verification_level: 'SMART_CV',
    base_xp: 60,
    instructions: [
      'Stand at bathroom sink',
      'Record a short 10-15s check-in while brushing teeth thoroughly'
    ],
    validation_rules: { minDurationSec: 10, requiredLabels: ['person', 'toothbrush'] }
  },
  {
    slug: 'hydrate-glass',
    title: 'Drink 500ml Water',
    description: 'Hydrate immediately upon waking to kickstart cellular metabolism.',
    category: 'health',
    proof_type: 'PHOTO',
    verification_level: 'HEURISTIC',
    base_xp: 40,
    instructions: [
      'Pour 500ml of cold or ambient water into a glass',
      'Drink the full glass at your counter',
      'Take a photo of the empty glass at the sink or counter'
    ],
    validation_rules: { minLuminance: 25, requiredLabels: ['glass', 'cup', 'sink'] }
  },
  {
    slug: 'morning-sunlight',
    title: 'Morning Sunlight View',
    description: 'Natural photons into eyes to trigger the cortisol awakening response and anchor circadian clock.',
    category: 'mindset',
    proof_type: 'PHOTO',
    verification_level: 'HEURISTIC',
    base_xp: 75,
    instructions: [
      'Step outside or to an open window/balcony',
      'Capture a wide photo of the morning sky and outdoor horizon'
    ],
    validation_rules: { minLuminance: 100, skyRatioMin: 0.25 }
  },
  {
    slug: 'clean-desk',
    title: 'Clear Workspace',
    description: 'Remove yesterday clutter and create an uncluttered surface for focused output.',
    category: 'environment',
    proof_type: 'PHOTO',
    verification_level: 'HEURISTIC',
    base_xp: 50,
    instructions: [
      'Remove dishes, trash, and extraneous clutter',
      'Straighten keyboard, mouse, and notepad',
      'Snap an overhead photo of the organized surface'
    ],
    validation_rules: { minLuminance: 35, requiredLabels: ['desk', 'table'] }
  },
  {
    slug: 'walk-2min',
    title: '2-Minute Outdoor Walk',
    description: 'Gentle aerobic locomotion to stimulate lymphatic flow and alertness.',
    category: 'exercise',
    proof_type: 'VIDEO',
    verification_level: 'SMART_CV',
    base_xp: 70,
    instructions: [
      'Step out the front door or hallway',
      'Record a brief video clip as you take a brisk 2-minute stride'
    ],
    validation_rules: { minDurationSec: 10, motionThreshold: 0.5 }
  },
  {
    slug: 'read-2pages',
    title: 'Read 2 Physical Pages',
    description: 'Engage cognitive focus on non-screen physical text.',
    category: 'mindset',
    proof_type: 'PHOTO',
    verification_level: 'HEURISTIC',
    base_xp: 60,
    instructions: [
      'Open a physical book or study material',
      'Read 2 full pages attentively',
      'Take a legible photo of the open book pages'
    ],
    validation_rules: { minLuminance: 40, requiredLabels: ['book', 'page'] }
  },
  {
    slug: 'body-stretch-30s',
    title: '30-Second Full Body Stretch',
    description: 'Decompress spinal column and open thoracic posture.',
    category: 'exercise',
    proof_type: 'VIDEO',
    verification_level: 'SMART_CV',
    base_xp: 50,
    instructions: [
      'Set camera to view full torso',
      'Perform an overhead extension and deep hamstring stretch for 30 seconds'
    ],
    validation_rules: { minDurationSec: 15, motionThreshold: 0.4 }
  },
  {
    slug: 'prep-tomorrow-clothes',
    title: 'Night Prep: Lay Out Tomorrow Gear',
    description: 'Evening friction-reduction ritual for frictionless next-morning execution.',
    category: 'routine',
    proof_type: 'PHOTO',
    verification_level: 'HEURISTIC',
    base_xp: 45,
    instructions: [
      'Select tomorrow workout or workday clothes and shoes',
      'Lay them out ready on a chair or bench',
      'Take a photo of the prepared setup'
    ],
    validation_rules: { minLuminance: 25, requiredLabels: ['clothes', 'shoes'] }
  }
];

export function seedDatabase(): { defaultUserId: string } {
  const db = DatabaseService.getDb();
  const now = new Date().toISOString();

  // 1. Seed Default User if none exists
  const existingUser = db.prepare('SELECT id FROM users LIMIT 1').get() as { id: string } | undefined;
  let defaultUserId = existingUser?.id;

  if (!defaultUserId) {
    defaultUserId = uuidv4();
    const insertUser = db.prepare(`
      INSERT INTO users (id, email, display_name, timezone, discipline_score, autonomy_level, current_streak, longest_streak, total_xp, grace_tokens, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);
    insertUser.run(
      defaultUserId,
      'alex@habitat.discipline',
      'Alex Mercer',
      'America/New_York',
      85,
      2,
      12,
      14,
      2450,
      1,
      now,
      now
    );
  }

  // 2. Seed Starter Tasks
  const insertTask = db.prepare(`
    INSERT OR IGNORE INTO tasks (id, slug, title, description, category, proof_type, verification_level, base_xp, instructions, validation_rules, is_starter, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
  `);

  for (const task of STARTER_TASKS) {
    const taskId = uuidv4();
    insertTask.run(
      taskId,
      task.slug,
      task.title,
      task.description,
      task.category,
      task.proof_type,
      task.verification_level,
      task.base_xp,
      JSON.stringify(task.instructions),
      JSON.stringify(task.validation_rules),
      now
    );
  }

  return { defaultUserId };
}
