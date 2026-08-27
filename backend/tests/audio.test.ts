// Integration Tests for V7 Psychoacoustic Audio Synthesizer & Hardware Siren Engine
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { AudioService } from '../src/modules/audio/audio.controller';

describe('V7 Psychoacoustic Audio: Binaural Waves, Carrier Frequencies & Escalation Curves', () => {
  let defaultUserId: string;
  let customProfileId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;
  });

  it('lists seeded psychoacoustic audio preset profiles', () => {
    const list = AudioService.getProfiles(defaultUserId);

    expect(list.length).toBeGreaterThanOrEqual(3);
    const spartan = list.find((p) => p.name === 'Spartan War Siren');
    expect(spartan).toBeDefined();
    expect(spartan?.baseFrequencyHz).toBe(880);
    expect(spartan?.binauralBeatHz).toBe(40.0);
    expect(spartan?.escalationProfile).toBe('EXPONENTIAL');
  });

  it('creates custom user synthesizer sound profile with strobe intervals', () => {
    const custom = AudioService.createProfile({
      userId: defaultUserId,
      name: 'Theta-to-Gamma Neural Disruptor',
      baseFrequencyHz: 528,
      binauralBeatHz: 40.0,
      escalationProfile: 'STROBE_PULSE',
      strobeIntervalMs: 150
    });

    expect(custom).toBeDefined();
    expect(custom?.name).toBe('Theta-to-Gamma Neural Disruptor');
    expect(custom?.baseFrequencyHz).toBe(528);
    expect(custom?.isPreset).toBe(false);

    customProfileId = custom!.id;
  });

  it('computes mathematical binaural frequency offsets and decibel volume gain curves', () => {
    const envelope = AudioService.getSynthesizerEnvelope(customProfileId);

    expect(envelope).toBeDefined();
    expect(envelope.leftChannelHz).toBe(528);
    expect(envelope.rightChannelHz).toBe(568); // 528 + 40Hz binaural offset
    expect(envelope.volumeEnvelope.length).toBeGreaterThanOrEqual(10);
    expect(envelope.volumeEnvelope[0].decibelLevel).toBeGreaterThanOrEqual(70);
  });
});
