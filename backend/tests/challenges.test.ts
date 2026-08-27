// Integration Tests for V5 Discipline Challenges & Tournament Arena
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { AuthService } from '../src/modules/auth/auth.service';
import { ChallengesService } from '../src/modules/challenges/challenges.controller';

describe('V5 Discipline Challenges: Tournaments, Sprints & Leaderboards', () => {
  let captainId: string;
  let rivalId: string;
  let challengeId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    captainId = seeded.defaultUserId;

    // Register second user for competitive leaderboard testing
    const rival = AuthService.register({
      email: 'spartan_rival@habitat.discipline',
      password: 'Discipline2026!',
      displayName: 'Leonidas Spartan'
    });
    rivalId = rival.user.id;
  });

  it('lists active seeded challenges', () => {
    const list = ChallengesService.getAllChallenges();
    expect(list.length).toBeGreaterThanOrEqual(1);
    expect(list.some((c) => c.title.includes('14-Day Morning Order'))).toBe(true);
    challengeId = list[0].id;
  });

  it('allows user to join challenge sprint tournament', () => {
    const participation = ChallengesService.joinChallenge(challengeId, captainId);

    expect(participation).toBeDefined();
    expect(participation.user_id).toBe(captainId);
    expect(participation.days_completed).toBe(0);

    // Second user joins as well
    ChallengesService.joinChallenge(challengeId, rivalId);
  });

  it('records daily challenge sprint progress and calculates running average resistance', () => {
    const day1Result = ChallengesService.recordChallengeDay({
      challengeId,
      userId: captainId,
      resistanceSeconds: 70
    });

    expect(day1Result.daysCompleted).toBe(1);
    expect(day1Result.isCompleted).toBe(false);

    // Rival records faster day 1 sprint
    ChallengesService.recordChallengeDay({
      challengeId,
      userId: rivalId,
      resistanceSeconds: 45
    });
  });

  it('computes real-time challenge leaderboard ranked by days and lowest resistance', () => {
    const leaderboard = ChallengesService.getLeaderboard(challengeId);

    expect(leaderboard.length).toBe(2);
    // Rival had 45s vs Captain 70s -> Rival ranks #1
    expect(leaderboard[0].userId).toBe(rivalId);
    expect(leaderboard[0].rank).toBe(1);
    expect(leaderboard[1].userId).toBe(captainId);
    expect(leaderboard[1].rank).toBe(2);
  });

  it('creates custom guild challenge with reward trophy', () => {
    const custom = ChallengesService.createChallenge({
      title: '7-Day Zero-Snooze Protocol',
      description: 'Zero snooze retries permitted for 7 consecutive days',
      durationDays: 7,
      rewardXp: 350,
      trophyName: 'Snooze Destroyer Trophy',
      taskIds: ['make-bed', 'pushups-10']
    });

    expect(custom).toBeDefined();
    expect(custom?.title).toBe('7-Day Zero-Snooze Protocol');
    expect(custom?.rewardXp).toBe(350);
  });
});
