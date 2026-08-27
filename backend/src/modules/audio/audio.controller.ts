// Psychoacoustic Audio Synthesizer & Hardware Siren Controller
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';

export class AudioService {
  public static getProfiles(userId?: string) {
    const db = DatabaseService.getDb();
    const rows = db.prepare(`
      SELECT * FROM audio_profiles 
      WHERE is_preset = 1 OR user_id = ? 
      ORDER BY is_preset DESC, name ASC
    `).all(userId || 'default-user') as any[];

    return rows.map((r) => ({
      id: r.id,
      name: r.name,
      baseFrequencyHz: r.base_frequency_hz,
      binauralBeatHz: r.binaural_beat_hz,
      escalationProfile: r.escalation_profile,
      strobeIntervalMs: r.strobe_interval_ms,
      isPreset: Boolean(r.is_preset),
      createdAt: r.created_at
    }));
  }

  public static getProfileById(profileId: string) {
    const db = DatabaseService.getDb();
    const r = db.prepare('SELECT * FROM audio_profiles WHERE id = ?').get(profileId) as any;
    if (!r) return null;

    return {
      id: r.id,
      name: r.name,
      baseFrequencyHz: r.base_frequency_hz,
      binauralBeatHz: r.binaural_beat_hz,
      escalationProfile: r.escalation_profile,
      strobeIntervalMs: r.strobe_interval_ms,
      isPreset: Boolean(r.is_preset),
      createdAt: r.created_at
    };
  }

  public static createProfile(params: {
    userId: string;
    name: string;
    baseFrequencyHz: number;
    binauralBeatHz: number;
    escalationProfile: string; // 'LINEAR' | 'EXPONENTIAL' | 'STROBE_PULSE'
    strobeIntervalMs?: number;
  }) {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO audio_profiles (id, user_id, name, base_frequency_hz, binaural_beat_hz, escalation_profile, strobe_interval_ms, is_preset, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?)
    `).run(
      id,
      params.userId,
      params.name.trim(),
      params.baseFrequencyHz,
      params.binauralBeatHz,
      params.escalationProfile,
      params.strobeIntervalMs || 200,
      now
    );

    return this.getProfileById(id);
  }

  public static getSynthesizerEnvelope(profileId: string) {
    const profile = this.getProfileById(profileId);
    if (!profile) {
      throw new Error('Audio profile not found.');
    }

    // Compute binaural channel frequencies
    const leftChannelHz = profile.baseFrequencyHz;
    const rightChannelHz = profile.baseFrequencyHz + profile.binauralBeatHz;

    // Generate 60-second decibel gain volume envelope
    const envelopePoints = [];
    for (let t = 0; t <= 60; t += 5) {
      let gain = 0.5; // start at 50%
      if (profile.escalationProfile === 'LINEAR') {
        gain = Math.min(1.0, 0.5 + (t / 60) * 0.5);
      } else if (profile.escalationProfile === 'EXPONENTIAL') {
        gain = Math.min(1.0, 0.4 + Math.pow(t / 60, 2) * 0.6);
      } else if (profile.escalationProfile === 'STROBE_PULSE') {
        gain = t % 10 === 0 ? 1.0 : 0.6;
      }
      envelopePoints.push({
        second: t,
        volumeGain: parseFloat(gain.toFixed(2)),
        decibelLevel: Math.round(70 + gain * 30) // 70dB to 100dB
      });
    }

    return {
      profileId: profile.id,
      profileName: profile.name,
      leftChannelHz,
      rightChannelHz,
      binauralBeatHz: profile.binauralBeatHz,
      escalationProfile: profile.escalationProfile,
      strobeIntervalMs: profile.strobeIntervalMs,
      volumeEnvelope: envelopePoints
    };
  }
}

export const audioController = Router();

// GET /api/v1/audio/profiles - List profiles
audioController.get('/profiles', (req: Request, res: Response) => {
  const userId = req.query.userId as string | undefined;
  const profiles = AudioService.getProfiles(userId);
  res.json({ success: true, count: profiles.length, data: profiles });
});

// POST /api/v1/audio/profiles - Create custom profile
audioController.post('/profiles', (req: Request, res: Response) => {
  try {
    const { userId, name, baseFrequencyHz, binauralBeatHz, escalationProfile, strobeIntervalMs } = req.body;
    if (!name || !baseFrequencyHz || !binauralBeatHz) {
      res.status(400).json({ success: false, error: 'name, baseFrequencyHz, and binauralBeatHz are required' });
      return;
    }

    const created = AudioService.createProfile({
      userId: userId || 'default-user',
      name,
      baseFrequencyHz: parseInt(baseFrequencyHz, 10),
      binauralBeatHz: parseFloat(binauralBeatHz),
      escalationProfile: escalationProfile || 'EXPONENTIAL',
      strobeIntervalMs: strobeIntervalMs ? parseInt(strobeIntervalMs, 10) : 200
    });

    res.status(201).json({ success: true, data: created });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/audio/profiles/:id - Get profile details
audioController.get('/profiles/:id', (req: Request, res: Response) => {
  const profile = AudioService.getProfileById(String(req.params.id));
  if (!profile) {
    res.status(404).json({ success: false, error: 'Audio profile not found' });
    return;
  }
  res.json({ success: true, data: profile });
});

// GET /api/v1/audio/profiles/:id/envelope - Synthesizer frequency envelope
audioController.get('/profiles/:id/envelope', (req: Request, res: Response) => {
  try {
    const envelope = AudioService.getSynthesizerEnvelope(String(req.params.id));
    res.json({ success: true, data: envelope });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});
