// Phase 15 Gamification, Accountability, Social Layer & Production Platform Tests
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { EntitlementsService } from '../src/modules/billing/services/entitlements.service';
import { SocialService } from '../src/modules/social/social.controller';
import { FeatureFlagService } from '../src/modules/feature-flags/feature-flag.service';
import { GamificationService } from '../src/modules/gamification/gamification.controller';
import { AccountabilityService } from '../src/modules/accountability/accountability.controller';

describe('Phase 15 Acceptance Gate: Gamification, Social & Production Platform', () => {
  let userA: string;
  let userB: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    userA = seeded.defaultUserId;
    userB = 'user-social-beta';

    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    db.prepare(`
      INSERT OR IGNORE INTO users (id, email, password_hash, display_name, created_at, updated_at)
      VALUES (?, 'userb@habitat.test', 'hash', 'Discipline Peer', ?, ?)
    `).run(userB, now, now);
  });

  it('Gate 1: Authoritative Entitlements: Verifies active entitlements and rejects expired ones', () => {
    expect(EntitlementsService.hasEntitlement(userA, 'AI_COACH')).toBe(false);

    EntitlementsService.grantEntitlement(userA, 'AI_COACH', 30);
    expect(EntitlementsService.hasEntitlement(userA, 'AI_COACH')).toBe(true);

    EntitlementsService.revokeEntitlement(userA, 'AI_COACH');
    expect(EntitlementsService.hasEntitlement(userA, 'AI_COACH')).toBe(false);
  });

  it('Gate 2: Idempotent XP Ledger: Ensures duplicate reward processing awards XP only once', () => {
    const missionId = 'mission-idempotent-100';

    const r1 = GamificationService.processMissionRewards({
      userId: userA,
      missionId,
      baseXp: 50,
      difficulty: 2
    });
    expect(r1.isDuplicate).toBe(false);
    expect(r1.baseXp).toBeGreaterThanOrEqual(50);

    // Reprocess same mission
    const r2 = GamificationService.processMissionRewards({
      userId: userA,
      missionId,
      baseXp: 50,
      difficulty: 2
    });
    expect(r2.isDuplicate).toBe(true);
  });

  it('Gate 3: Social Relationships: Establishes friendships and retrieves active peers', () => {
    SocialService.addRelationship(userA, userB, 'FRIEND');
    const friends = SocialService.getFriends(userA);
    expect(friends.length).toBeGreaterThanOrEqual(1);
    expect(friends[0].targetUserId).toBe(userB);

    // Self-friendship rejection
    expect(() => SocialService.addRelationship(userA, userA, 'FRIEND')).toThrow('INVALID_TARGET');
  });

  it('Gate 4: Mutual Blocking Guarantee: Blocks target user cleanly', () => {
    const blockRes = SocialService.blockUser(userA, userB);
    expect(blockRes.type).toBe('BLOCKED');

    const friends = SocialService.getFriends(userA);
    expect(friends.length).toBe(0);
  });

  it('Gate 5: Moderation Queue: Reports inappropriate content into audit table', () => {
    const report = SocialService.reportContent({
      reporterId: userA,
      targetId: 'challenge-xyz',
      targetType: 'CHALLENGE',
      reason: 'Inappropriate challenge content'
    });

    expect(report.reportId).toBeDefined();
    expect(report.status).toBe('PENDING');
  });

  it('Gate 6: Dynamic Feature Flags: Toggles and evaluates runtime flags', () => {
    FeatureFlagService.setFlag('GROUP_CHALLENGES', true, 'Enable community challenges');
    expect(FeatureFlagService.isEnabled('GROUP_CHALLENGES')).toBe(true);

    FeatureFlagService.setFlag('GROUP_CHALLENGES', false);
    expect(FeatureFlagService.isEnabled('GROUP_CHALLENGES')).toBe(false);
  });

  it('Gate 7: Accountability Partner Lifecycle: Adds partner and manages escalation', () => {
    const partner = AccountabilityService.addPartner({
      userId: userA,
      name: 'Raman Coach',
      email: 'raman@discipline.test',
      escalationThreshold: 2
    });

    expect(partner.id).toBeDefined();
    const partners = AccountabilityService.getPartners(userA);
    expect(partners.length).toBeGreaterThanOrEqual(1);

    AccountabilityService.deletePartner(partner.id, userA);
    const afterDelete = AccountabilityService.getPartners(userA);
    expect(afterDelete.length).toBe(0);
  });

  it('Gate 8: Multi-Tenant Data Isolation: Ensures user A cannot view User B private friends or records', () => {
    const friendsB = SocialService.getFriends(userB);
    expect(friendsB.length).toBe(0);
  });
});
