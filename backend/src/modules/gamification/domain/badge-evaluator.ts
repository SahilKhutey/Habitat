// Canonical Badge & Achievement Evaluator

export interface BadgeDefinition {
  slug: string;
  name: string;
  description: string;
  category: 'STREAK' | 'MASTERY' | 'SPEED' | 'DEFENSE';
  icon: string;
  xpReward: number;
}

export const CANONICAL_BADGES: BadgeDefinition[] = [
  {
    slug: 'first-step',
    name: 'First Step to Order',
    description: 'Complete your first morning discipline mission.',
    category: 'MASTERY',
    icon: 'shield_moon',
    xpReward: 50
  },
  {
    slug: 'streak-7',
    name: '7-Day Iron Will',
    description: 'Maintain an unbroken 7-day discipline streak.',
    category: 'STREAK',
    icon: 'local_fire_department',
    xpReward: 100
  },
  {
    slug: 'streak-30',
    name: '30-Day Spartan',
    description: 'Complete 30 consecutive days without breaking discipline.',
    category: 'STREAK',
    icon: 'military_tech',
    xpReward: 500
  },
  {
    slug: 'zero-hesitation',
    name: 'Zero Hesitation',
    description: 'Earn 5 Instant Action Speed Bonuses (under 120s resistance).',
    category: 'SPEED',
    icon: 'bolt',
    xpReward: 150
  },
  {
    slug: 'grace-vault-guardian',
    name: 'Grace Vault Guardian',
    description: 'Accumulate the maximum capacity of 3 Grace Tokens.',
    category: 'DEFENSE',
    icon: 'security',
    xpReward: 75
  }
];

export class BadgeEvaluator {
  public static evaluateBadges(metrics: {
    totalCompletedMissions: number;
    currentStreak: number;
    speedBonusCount: number;
    graceTokens: number;
  }): { slug: string; badge: BadgeDefinition }[] {
    const unlocked: { slug: string; badge: BadgeDefinition }[] = [];

    for (const b of CANONICAL_BADGES) {
      let isUnlocked = false;

      switch (b.slug) {
        case 'first-step':
          isUnlocked = metrics.totalCompletedMissions >= 1;
          break;
        case 'streak-7':
          isUnlocked = metrics.currentStreak >= 7;
          break;
        case 'streak-30':
          isUnlocked = metrics.currentStreak >= 30;
          break;
        case 'zero-hesitation':
          isUnlocked = metrics.speedBonusCount >= 5;
          break;
        case 'grace-vault-guardian':
          isUnlocked = metrics.graceTokens >= 3;
          break;
      }

      if (isUnlocked) {
        unlocked.push({ slug: b.slug, badge: b });
      }
    }

    return unlocked;
  }
}
