// Idempotent Development & Production Seed for Habitat (Prisma Engine)
import { PrismaClient } from '@prisma/client';
import * as crypto from 'crypto';

export const STARTER_TEMPLATES = [
  {
    id: 'tpl-make-bed',
    name: 'Make Your Bed',
    description: 'Smooth sheets flat and align pillows to establish immediate order in your sleeping quarters.',
    instructions: 'Step out of bed completely. Straighten quilt and align pillows flat. Snap a photo of completed bed.',
    category: 'morning',
    proofType: 'PHOTO',
    defaultDifficulty: 1,
    baseXp: 50,
    estimatedDurationSec: 60,
    iconName: 'bed',
    validationRules: { minLuminance: 30, requiredLabels: ['bed', 'pillow'] }
  },
  {
    id: 'tpl-pushups-10',
    name: '10 Morning Push-Ups',
    description: 'Elevate heart rate and activate neuromuscular systems with 10 strict repetitions.',
    instructions: 'Prop camera 5-6 feet away. Execute 10 chest-to-floor push-ups in under 60 seconds.',
    category: 'physical',
    proofType: 'VIDEO',
    defaultDifficulty: 3,
    baseXp: 30,
    estimatedDurationSec: 45,
    iconName: 'fitness_center',
    validationRules: { minRepetitions: 10, minDurationSec: 10 }
  },
  {
    id: 'tpl-brush-teeth',
    name: 'Brush Teeth (2 Minutes)',
    description: 'Oral hygiene routine signaling metabolic alertness to your nervous system.',
    instructions: 'Record short 10-15s check-in while brushing teeth thoroughly at the sink.',
    category: 'personal',
    proofType: 'PHOTO',
    defaultDifficulty: 1,
    baseXp: 15,
    estimatedDurationSec: 120,
    iconName: 'clean_hands',
    validationRules: { minLuminance: 25 }
  },
  {
    id: 'tpl-hydrate-glass',
    name: 'Drink 500ml Water',
    description: 'Rehydrate immediately upon waking to kickstart cellular metabolism.',
    instructions: 'Drink a full glass of water. Take a photo of the empty glass at the counter.',
    category: 'morning',
    proofType: 'PHOTO',
    defaultDifficulty: 1,
    baseXp: 40,
    estimatedDurationSec: 30,
    iconName: 'water_drop',
    validationRules: { minLuminance: 25 }
  },
  {
    id: 'tpl-morning-sunlight',
    name: 'Morning Sunlight Exposure',
    description: 'Natural outdoor photons into eyes to trigger the cortisol awakening response.',
    instructions: 'Step outside within 3 minutes of waking. Snap a clear photo of the outdoor horizon.',
    category: 'morning',
    proofType: 'PHOTO',
    defaultDifficulty: 2,
    baseXp: 75,
    estimatedDurationSec: 180,
    iconName: 'wb_sunny',
    validationRules: { minLuminance: 100 }
  },
  {
    id: 'tpl-clean-desk',
    name: 'Clear Workspace',
    description: 'Remove clutter and create an organized surface for focused output.',
    instructions: 'Straighten keyboard and desk surface. Snap an overhead photo.',
    category: 'environment',
    proofType: 'PHOTO',
    defaultDifficulty: 1,
    baseXp: 50,
    estimatedDurationSec: 120,
    iconName: 'table_restaurant',
    validationRules: { minLuminance: 35 }
  },
  {
    id: 'tpl-walk-2min',
    name: '2-Minute Outdoor Walk',
    description: 'Gentle aerobic locomotion to stimulate lymphatic flow and alertness.',
    instructions: 'Step out the front door and take a brisk 2-minute stride.',
    category: 'physical',
    proofType: 'PHOTO',
    defaultDifficulty: 2,
    baseXp: 70,
    estimatedDurationSec: 120,
    iconName: 'directions_walk',
    validationRules: { minLuminance: 30 }
  },
  {
    id: 'tpl-read-2pages',
    name: 'Read 2 Physical Pages',
    description: 'Engage cognitive focus on non-screen physical text.',
    instructions: 'Read 2 full physical pages attentively. Take a legible photo of the open book.',
    category: 'mind',
    proofType: 'PHOTO',
    defaultDifficulty: 2,
    baseXp: 60,
    estimatedDurationSec: 180,
    iconName: 'menu_book',
    validationRules: { minLuminance: 40 }
  },
  {
    id: 'tpl-body-stretch-30s',
    name: '30-Second Full Body Stretch',
    description: 'Decompress spinal column and open thoracic posture.',
    instructions: 'Perform overhead extensions and deep hamstring mobility stretches.',
    category: 'physical',
    proofType: 'VIDEO',
    defaultDifficulty: 1,
    baseXp: 50,
    estimatedDurationSec: 30,
    iconName: 'self_improvement',
    validationRules: { minDurationSec: 15 }
  },
  {
    id: 'tpl-prep-tomorrow-clothes',
    name: 'Night Prep: Lay Out Tomorrow Gear',
    description: 'Evening friction-reduction ritual for frictionless next-morning execution.',
    instructions: 'Select tomorrow workout clothes and shoes. Lay them out ready.',
    category: 'environment',
    proofType: 'PHOTO',
    defaultDifficulty: 1,
    baseXp: 45,
    estimatedDurationSec: 90,
    iconName: 'checkroom',
    validationRules: { minLuminance: 25 }
  }
];

export function hashPassword(password: string): string {
  return crypto.createHash('sha256').update(password).digest('hex');
}

export async function main(client?: PrismaClient): Promise<{ defaultUserId: string }> {
  console.log('[Prisma Seed] Starting idempotent database seed...');
  const prisma = client ?? new PrismaClient();

  const defaultPasswordHash = hashPassword('Discipline2026!');
  const defaultUserId = 'usr_seed_alex_mercer';

  // 1. Seed Default User
  const defaultUser = await prisma.user.upsert({
    where: { email: 'alex@habitat.discipline' },
    update: {
      displayName: 'Alex Mercer',
      timezone: 'America/New_York',
      disciplineScore: 85,
      autonomyLevel: 2
    },
    create: {
      id: defaultUserId,
      email: 'alex@habitat.discipline',
      passwordHash: defaultPasswordHash,
      displayName: 'Alex Mercer',
      timezone: 'America/New_York',
      disciplineScore: 85,
      autonomyLevel: 2
    }
  });

  // 1b. Seed Streak & XP for Default User
  await prisma.streak.upsert({
    where: { userId: defaultUser.id },
    update: {
      currentStreak: 12,
      longestStreak: 14,
      graceTokens: 1
    },
    create: {
      userId: defaultUser.id,
      currentStreak: 12,
      longestStreak: 14,
      graceTokens: 1
    }
  });

  await prisma.xpTransaction.upsert({
    where: { id: 'xp_seed_initial_alex' },
    update: { amount: 2450 },
    create: {
      id: 'xp_seed_initial_alex',
      userId: defaultUser.id,
      amount: 2450,
      reason: 'INITIAL_SEEDED_XP',
      sourceType: 'SEED'
    }
  });

  // 2. Seed 10 Starter Task Templates
  let sortOrder = 0;
  for (const tpl of STARTER_TEMPLATES) {
    await prisma.taskTemplate.upsert({
      where: { id: tpl.id },
      update: {
        name: tpl.name,
        description: tpl.description,
        instructions: tpl.instructions,
        category: tpl.category,
        proofType: tpl.proofType,
        defaultDifficulty: tpl.defaultDifficulty,
        baseXp: tpl.baseXp,
        estimatedDurationSec: tpl.estimatedDurationSec,
        iconName: tpl.iconName,
        validationRules: JSON.stringify(tpl.validationRules),
        sortOrder: sortOrder++
      },
      create: {
        id: tpl.id,
        name: tpl.name,
        description: tpl.description,
        instructions: tpl.instructions,
        category: tpl.category,
        proofType: tpl.proofType,
        defaultDifficulty: tpl.defaultDifficulty,
        baseXp: tpl.baseXp,
        estimatedDurationSec: tpl.estimatedDurationSec,
        iconName: tpl.iconName,
        validationRules: JSON.stringify(tpl.validationRules),
        isActive: true,
        sortOrder: sortOrder++
      }
    });
  }

  // 3. Seed 10 Global Starter Tasks
  let taskOrder = 0;
  for (const tpl of STARTER_TEMPLATES) {
    const slug = tpl.id.replace('tpl-', '');
    const mult = tpl.defaultDifficulty === 3 ? 1.5 : (tpl.defaultDifficulty === 2 ? 1.25 : 1.0);
    const xpReward = Math.round(tpl.baseXp * mult);
    const diffVal = tpl.defaultDifficulty === 3 ? 3 : (tpl.defaultDifficulty === 2 ? 2 : 1);

    await prisma.task.upsert({
      where: { slug },
      update: {
        title: tpl.name,
        name: tpl.name,
        description: tpl.description,
        instructions: tpl.instructions,
        category: tpl.category,
        proofType: tpl.proofType,
        verificationType: 'BASIC',
        difficulty: diffVal,
        baseXp: tpl.baseXp,
        xpReward,
        estimatedDurationSec: tpl.estimatedDurationSec,
        iconName: tpl.iconName,
        validationRules: JSON.stringify(tpl.validationRules),
        status: 'ACTIVE',
        isStarter: true,
        sortOrder: taskOrder++
      },
      create: {
        id: `task_${slug}`,
        templateId: tpl.id,
        slug,
        title: tpl.name,
        name: tpl.name,
        description: tpl.description,
        instructions: tpl.instructions,
        category: tpl.category,
        proofType: tpl.proofType,
        verificationType: 'BASIC',
        difficulty: diffVal,
        baseXp: tpl.baseXp,
        xpReward,
        estimatedDurationSec: tpl.estimatedDurationSec,
        iconName: tpl.iconName,
        validationRules: JSON.stringify(tpl.validationRules),
        status: 'ACTIVE',
        isActive: true,
        isStarter: true,
        sortOrder: taskOrder++
      }
    });
  }

  // 4. Seed Starter Challenges
  await prisma.challenge.upsert({
    where: { id: 'challenge-14-order' },
    update: {
      title: '14-Day Morning Order Tournament',
      description: 'Execute your morning bed and sunlight missions for 14 consecutive days without missing a beat.',
      rewardXp: 500
    },
    create: {
      id: 'challenge-14-order',
      title: '14-Day Morning Order Tournament',
      description: 'Execute your morning bed and sunlight missions for 14 consecutive days without missing a beat.',
      durationDays: 14,
      rewardXp: 500,
      trophyName: 'Morning Sovereign Trophy',
      taskIds: JSON.stringify(['make-bed', 'morning-sunlight']),
      startDate: new Date(),
      endDate: new Date('2026-12-31T23:59:59.000Z'),
      isActive: true
    }
  });

  // 5. Seed Psychoacoustic Sound Profiles
  await prisma.audioProfile.upsert({
    where: { id: 'audio-exponential-40hz' },
    update: {
      name: 'Gamma 40Hz Escalation Matrix'
    },
    create: {
      id: 'audio-exponential-40hz',
      name: 'Gamma 40Hz Escalation Matrix',
      baseFrequencyHz: 440,
      binauralBeatHz: 40.0,
      escalationProfile: 'EXPONENTIAL',
      strobeIntervalMs: 200,
      isPreset: true
    }
  });

  await prisma.audioProfile.upsert({
    where: { id: 'audio-strobe-alert' },
    update: {
      name: 'Rapid Strobe Arousal Protocol'
    },
    create: {
      id: 'audio-strobe-alert',
      name: 'Rapid Strobe Arousal Protocol',
      baseFrequencyHz: 880,
      binauralBeatHz: 40.0,
      escalationProfile: 'PULSE_TRAIN',
      strobeIntervalMs: 100,
      isPreset: true
    }
  });

  // 6. Seed Feature Flags
  await prisma.featureFlag.upsert({
    where: { key: 'flag-mesh-sync' },
    update: { isEnabled: true },
    create: {
      id: 'flag_1',
      key: 'flag-mesh-sync',
      isEnabled: true,
      description: 'Multi-device alarm mesh synchronization'
    }
  });

  await prisma.featureFlag.upsert({
    where: { key: 'flag-smart-cv' },
    update: { isEnabled: true },
    create: {
      id: 'flag_2',
      key: 'flag-smart-cv',
      isEnabled: true,
      description: 'MoveNet neural computer vision proof verification'
    }
  });

  console.log(`[Prisma Seed] Seed complete. Default User ID: ${defaultUser.id}`);
  return { defaultUserId: defaultUser.id };
}

if (require.main === module) {
  const prisma = new PrismaClient();
  main(prisma)
    .catch((e) => {
      console.error(e);
      process.exit(1);
    })
    .finally(async () => {
      await prisma.$disconnect();
    });
}
