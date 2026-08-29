// Controlled Real-Media Adversarial Corpus Manifest & Ground Truth Registry

export type FixtureCategory =
  | 'genuine'
  | 'static-photo'
  | 'screen-replay'
  | 'looped-video'
  | 'temporal-manipulation'
  | 'multi-person'
  | 'stale-evidence';

export interface AdversarialFixtureMetadata {
  id: string;
  name: string;
  category: FixtureCategory;
  groundTruth: 'genuine' | 'spoof';
  expectedDecision: 'ACCEPT' | 'REVIEW' | 'REJECT' | 'REJECT_OR_REVIEW';
  attackClass: string;
  deviceContext: string;
  description: string;
}

export const REAL_MEDIA_CORPUS: AdversarialFixtureMetadata[] = [
  // --- Genuine Exercise Controls ---
  {
    id: 'genuine_001_standard_pushups',
    name: 'Genuine 10-Rep Pushups (Standard Lighting)',
    category: 'genuine',
    groundTruth: 'genuine',
    expectedDecision: 'ACCEPT',
    attackClass: 'none (control)',
    deviceContext: 'Pixel 8 / Normal Front Camera / Natural Motion',
    description: 'Human subject performing 10 biomechanically valid push-ups at 10 FPS with continuous biological micro-jitter.'
  },
  {
    id: 'genuine_002_angled_pushups',
    name: 'Genuine 10-Rep Pushups (45-deg Angle)',
    category: 'genuine',
    groundTruth: 'genuine',
    expectedDecision: 'ACCEPT',
    attackClass: 'none (control)',
    deviceContext: 'Samsung S23 / Side 45-deg Angle / Good Form',
    description: 'Human subject performing push-ups at an angle with clear full range of motion.'
  },
  {
    id: 'genuine_003_suboptimal_lighting',
    name: 'Genuine Pushups (Suboptimal / Dim Lighting)',
    category: 'genuine',
    groundTruth: 'genuine',
    expectedDecision: 'ACCEPT', // Or REVIEW
    attackClass: 'none (control)',
    deviceContext: 'OnePlus 11 / Dim Room / Low Lux',
    description: 'Genuine human exercise in dim morning lighting with genuine limb dynamics.'
  },

  // --- Attack Class 1: Static Photo Attack ---
  {
    id: 'spoof_001_static_printed_photo',
    name: 'Printed Static Photo Held Before Camera',
    category: 'static-photo',
    groundTruth: 'spoof',
    expectedDecision: 'REJECT_OR_REVIEW',
    attackClass: '1. Static image',
    deviceContext: 'Pixel 8 / Glossy 4x6 Photo Held to Camera',
    description: 'Identical pixel bytes across frames with zero optical entropy or joint angular motion.'
  },

  // --- Attack Class 2: Photo on Phone Screen ---
  {
    id: 'spoof_002_phone_screen_photo',
    name: 'Still Image Displayed on iPhone Screen',
    category: 'screen-replay',
    groundTruth: 'spoof',
    expectedDecision: 'REJECT_OR_REVIEW',
    attackClass: '2. Photo replay',
    deviceContext: 'Pixel 8 recording iPhone 15 OLED display',
    description: 'Photo on mobile screen with static pose landmarks and absence of human respiration jitter.'
  },

  // --- Attack Class 3: Looped Video Repetition ---
  {
    id: 'spoof_003_looped_single_rep',
    name: 'Single Repetition Looped 10 Times (A-B-C-D-A-B-C-D)',
    category: 'looped-video',
    groundTruth: 'spoof',
    expectedDecision: 'REJECT_OR_REVIEW',
    attackClass: '3. Looped video',
    deviceContext: 'Pixel 8 / Synthetic Periodic Frame Cycle',
    description: 'Repetitive frame sequences with identical frame hashes occurring every 20 frames.'
  },

  // --- Attack Class 4: Monitor Screen Recording ---
  {
    id: 'spoof_004_monitor_screen_recording',
    name: 'Desktop Monitor Recording of Past Exercise',
    category: 'screen-replay',
    groundTruth: 'spoof',
    expectedDecision: 'REJECT_OR_REVIEW',
    attackClass: '4. Screen recording',
    deviceContext: 'Samsung S23 recording 27-inch 4K IPS monitor',
    description: 'Captured video played on computer monitor exhibiting artificial frame step intervals.'
  },

  // --- Attack Class 5: Temporal Timestamp Manipulation ---
  {
    id: 'spoof_005_temporal_inversion_jump',
    name: 'Temporal Timestamp Jump & Inverted Framerate',
    category: 'temporal-manipulation',
    groundTruth: 'spoof',
    expectedDecision: 'REJECT_OR_REVIEW',
    attackClass: '5. Temporal manipulation',
    deviceContext: 'Pixel 8 / Manipulated EXIF & Frame Timestamps',
    description: 'Frames submitted out of order with anomalous velocity jumps (> 500 deg/s).'
  },

  // --- Attack Class 6: Multi-Person / Non-Isolated Subject ---
  {
    id: 'spoof_006_crowded_room_multi_person',
    name: 'Multi-Person Non-Isolated Room',
    category: 'multi-person',
    groundTruth: 'spoof',
    expectedDecision: 'REJECT_OR_REVIEW',
    attackClass: '6. Multiple-person scenario',
    deviceContext: 'Pixel 8 / Busy Gym Floor / Multiple Moving Bodies',
    description: 'Inconsistent bounding centroids and erratic target subject switching.'
  },

  // --- Attack Class 7: Stale Replayed Evidence Nonce ---
  {
    id: 'spoof_007_stale_replay_nonce_mismatch',
    name: 'Replayed Historical Proof with Forged Nonce',
    category: 'stale-evidence',
    groundTruth: 'spoof',
    expectedDecision: 'REJECT_OR_REVIEW',
    attackClass: '7. Stale/replayed evidence',
    deviceContext: 'Pixel 8 / Captured yesterday, submitted today',
    description: 'Historical valid telemetry re-submitted against an active challenge with invalid nonce/hash.'
  }
];
