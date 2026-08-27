// Integration Tests for V6 Physical NFC / QR Hardware Anchors
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { AnchorsService } from '../src/modules/anchors/anchors.controller';

describe('V6 Physical NFC / QR Hardware Anchors: Cryptographic Nonce Verification', () => {
  let defaultUserId: string;
  let anchorId: string;
  let challengePayload: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;
  });

  it('pairs a physical NFC hardware anchor with location label and secret key', () => {
    const anchor = AnchorsService.pairAnchor({
      userId: defaultUserId,
      name: 'Bathroom Sink Tag',
      anchorType: 'NFC_TAG',
      locationLabel: 'Master Bathroom Sink',
      hardwareIdentifier: 'NFC-213-SINK'
    });

    expect(anchor).toBeDefined();
    expect(anchor?.name).toBe('Bathroom Sink Tag');
    expect(anchor?.locationLabel).toBe('Master Bathroom Sink');
    expect(anchor?.anchorType).toBe('NFC_TAG');
    anchorId = anchor!.id;
  });

  it('lists active hardware anchors for the user', () => {
    const list = AnchorsService.getAnchors(defaultUserId);
    expect(list.length).toBe(1);
    expect(list[0].id).toBe(anchorId);
  });

  it('generates a 60-second time-bound HMAC-SHA256 nonce challenge', () => {
    const challenge = AnchorsService.generateChallenge(anchorId);

    expect(challenge).toBeDefined();
    expect(challenge.anchorId).toBe(anchorId);
    expect(challenge.nonce).toBeDefined();
    expect(challenge.signature).toBeDefined();
    expect(challenge.challengePayload).toContain(anchorId);

    challengePayload = challenge.challengePayload;
  });

  it('successfully verifies physical hardware scan and logs verification', () => {
    const result = AnchorsService.verifyAnchorScan({
      userId: defaultUserId,
      anchorId,
      challengePayload
    });

    expect(result.isValid).toBe(true);
    expect(result.locationLabel).toBe('Master Bathroom Sink');
    expect(result.verifiedAt).toBeDefined();
  });

  it('rejects replay attack when attempting to reuse the exact same physical nonce', () => {
    const replayResult = AnchorsService.verifyAnchorScan({
      userId: defaultUserId,
      anchorId,
      challengePayload
    });

    expect(replayResult.isValid).toBe(false);
    expect(replayResult.reason).toContain('Replay attack rejected');
  });
});
