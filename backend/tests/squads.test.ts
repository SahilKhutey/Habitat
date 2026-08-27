// Integration Tests for V3 Social Squads & Collective Discipline Guilds
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { AuthService } from '../src/modules/auth/auth.service';
import { SquadsService } from '../src/modules/squads/squads.controller';

describe('V3 Social Squads: Guilds, Collective Streaks & Nudges', () => {
  let captainId: string;
  let memberId: string;
  let squadId: string;
  let inviteCode: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    captainId = seeded.defaultUserId;

    // Register 2nd user as warrior member
    const member = AuthService.register({
      email: 'david@habitat.discipline',
      password: 'StayHard2026!',
      displayName: 'David Goggins'
    });
    memberId = member.user.id;
  });

  it('creates a discipline squad with Captain and generates unique invite code', () => {
    const squad = SquadsService.createSquad({
      userId: captainId,
      name: 'Spartan Vanguard'
    });

    expect(squad).toBeDefined();
    expect(squad?.name).toBe('Spartan Vanguard');
    expect(squad?.inviteCode.length).toBe(6);
    expect(squad?.memberCount).toBe(1);
    expect(squad?.members[0].role).toBe('CAPTAIN');
    expect(squad?.collectiveStreak).toBe(1);

    squadId = squad!.id;
    inviteCode = squad!.inviteCode;
  });

  it('allows second user to join squad via invite code', () => {
    const updated = SquadsService.joinSquad({
      userId: memberId,
      inviteCode
    });

    expect(updated).toBeDefined();
    expect(updated?.memberCount).toBe(2);
    const joinedMember = updated?.members.find((m) => m.userId === memberId);
    expect(joinedMember).toBeDefined();
    expect(joinedMember?.role).toBe('MEMBER');
    expect(joinedMember?.displayName).toBe('David Goggins');
  });

  it('queries squad overview and member completion rate', () => {
    const overview = SquadsService.getSquadOverview(squadId);

    expect(overview).toBeDefined();
    expect(overview?.name).toBe('Spartan Vanguard');
    expect(overview?.members.length).toBe(2);
    expect(overview?.todayCompletionRate).toBeDefined();
  });

  it('queries real-time squad discipline event feed', () => {
    const feed = SquadsService.getSquadFeed(squadId);

    expect(feed.length).toBeGreaterThanOrEqual(2);
    expect(feed.some((e) => e.eventType === 'SQUAD_CREATED')).toBe(true);
    expect(feed.some((e) => e.eventType === 'MEMBER_JOINED')).toBe(true);
  });

  it('dispatches urgent wake-up nudge to a lagging member and logs feed event', () => {
    const result = SquadsService.nudgeMember({
      squadId,
      senderUserId: captainId,
      targetUserId: memberId
    });

    expect(result.success).toBe(true);
    expect(result.message).toContain('Wakeup Nudge');

    const feed = SquadsService.getSquadFeed(squadId);
    const nudgeEvent = feed.find((e) => e.eventType === 'NUDGE_SENT');
    expect(nudgeEvent).toBeDefined();
  });
});
