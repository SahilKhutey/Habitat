// High-Fidelity Media Stream Generator for Adversarial Corpus Fixtures
import { FramePoseRecord } from '../../../src/modules/verification/domain/evidence.types';
import { VisionFrame } from '../../../src/modules/verification/domain/vision-provider.interface';
import { AdversarialFixtureMetadata } from './corpus-manifest';

export interface GeneratedFixtureData {
  metadata: AdversarialFixtureMetadata;
  frames: VisionFrame[];
  trajectory: FramePoseRecord[];
  sessionNonce: string;
}

/**
 * Synthesizes an RGB24 pixel buffer (192x192x3) containing a person in exercise stance
 */
function createSynthesizedRgbFrame(headYNorm: number, armYNorm: number, brightnessOffset = 0): Uint8Array {
  const buffer = new Uint8Array(192 * 192 * 3);

  for (let y = 0; y < 192; y++) {
    const normY = y / 192;
    for (let x = 0; x < 192; x++) {
      const normX = x / 192;
      const idx = (y * 192 + x) * 3;

      // Draw background ambient gradient
      buffer[idx] = Math.min(255, Math.max(0, 40 + (y % 10) + brightnessOffset));
      buffer[idx + 1] = Math.min(255, Math.max(0, 45 + (x % 10) + brightnessOffset));
      buffer[idx + 2] = Math.min(255, Math.max(0, 55 + brightnessOffset));

      // Draw head circle
      const headDist = Math.hypot(normX - 0.18, normY - headYNorm);
      if (headDist < 0.06) {
        buffer[idx] = 210;
        buffer[idx + 1] = 180;
        buffer[idx + 2] = 150;
      }

      // Draw arm segments
      const armDist = Math.hypot(normX - 0.30, normY - armYNorm);
      if (armDist < 0.05) {
        buffer[idx] = 210;
        buffer[idx + 1] = 180;
        buffer[idx + 2] = 150;
      }

      // Draw torso line
      if (normX >= 0.40 && normX <= 0.62 && Math.abs(normY - (headYNorm + 0.10)) < 0.05) {
        buffer[idx] = 180;
        buffer[idx + 1] = 70;
        buffer[idx + 2] = 70;
      }

      // Draw legs / floor contact
      if (normX >= 0.68 && normX <= 0.88 && Math.abs(normY - 0.65) < 0.05) {
        buffer[idx] = 60;
        buffer[idx + 1] = 60;
        buffer[idx + 2] = 140;
      }
    }
  }

  return buffer;
}

export class AdversarialMediaGenerator {
  /**
   * Generates a concrete test fixture stream matching the ground-truth metadata specifications
   */
  public static generate(metadata: AdversarialFixtureMetadata): GeneratedFixtureData {
    // 6 frames provides full representative motion trajectory while ensuring swift execution on CPU
    const totalFrames = 6;
    const frames: VisionFrame[] = [];
    const trajectory: FramePoseRecord[] = [];
    const sessionNonce = `challenge_nonce_${metadata.id}`;

    switch (metadata.id) {
      // 1. Genuine Controls
      case 'genuine_001_standard_pushups':
      case 'genuine_002_angled_pushups':
      case 'genuine_003_suboptimal_lighting': {
        const isDim = metadata.id === 'genuine_003_suboptimal_lighting';
        const brightOffset = isDim ? -20 : 0;

        for (let f = 0; f < totalFrames; f++) {
          const timestampMs = f * 150;
          const repPhase = (f % 6) / 6;
          const depth = Math.sin(repPhase * Math.PI);
          const jitter = (Math.sin(f * 1.7) + Math.cos(f * 2.3)) * 0.8;
          const elbowAngle = 165 - depth * 85 + jitter;

          const armY = 0.40 + depth * 0.25;
          const headY = 0.30 + depth * 0.15;
          const data = createSynthesizedRgbFrame(headY, armY, brightOffset);

          frames.push({
            timestampMs,
            frameIndex: f,
            frameHash: `hash_${metadata.id}_${f}`,
            width: 192,
            height: 192,
            data
          });

          trajectory.push({
            timestampMs,
            frameIndex: f,
            frameHash: `hash_${metadata.id}_${f}`,
            keypoints: [],
            leftElbowAngleDeg: elbowAngle,
            rightElbowAngleDeg: elbowAngle,
            bodyAlignmentAngleDeg: 170 + jitter * 0.5
          });
        }
        break;
      }

      // Attack 1: Static Printed Photo
      case 'spoof_001_static_printed_photo': {
        const staticData = createSynthesizedRgbFrame(0.40, 0.55);
        const identicalHash = 'identical_static_frame_hash_sha256';

        for (let f = 0; f < totalFrames; f++) {
          const timestampMs = f * 150;
          frames.push({
            timestampMs,
            frameIndex: f,
            frameHash: identicalHash,
            width: 192,
            height: 192,
            data: staticData
          });

          trajectory.push({
            timestampMs,
            frameIndex: f,
            frameHash: identicalHash,
            keypoints: [],
            leftElbowAngleDeg: 90,
            rightElbowAngleDeg: 90,
            bodyAlignmentAngleDeg: 170
          });
        }
        break;
      }

      // Attack 2: Photo on Phone Screen
      case 'spoof_002_phone_screen_photo': {
        const screenData = createSynthesizedRgbFrame(0.40, 0.50);

        for (let f = 0; f < totalFrames; f++) {
          const timestampMs = f * 150;
          const toggleHash = `screen_photo_${f % 2}`;
          frames.push({
            timestampMs,
            frameIndex: f,
            frameHash: toggleHash,
            width: 192,
            height: 192,
            data: screenData
          });

          trajectory.push({
            timestampMs,
            frameIndex: f,
            frameHash: toggleHash,
            keypoints: [],
            leftElbowAngleDeg: 165,
            rightElbowAngleDeg: 165,
            bodyAlignmentAngleDeg: 170
          });
        }
        break;
      }

      // Attack 3: Looped Video Repetition (A-B-C-D-A-B-C-D)
      case 'spoof_003_looped_single_rep': {
        for (let f = 0; f < totalFrames; f++) {
          const loopFrameIndex = f % 2; // Repeating 2-frame cycle
          const timestampMs = f * 150;
          const depth = loopFrameIndex === 1 ? 0.8 : 0.2;
          const elbowAngle = 165 - depth * 85;

          const data = createSynthesizedRgbFrame(0.30 + depth * 0.15, 0.40 + depth * 0.25);

          frames.push({
            timestampMs,
            frameIndex: f,
            frameHash: `loop_chunk_hash_${loopFrameIndex}`,
            width: 192,
            height: 192,
            data
          });

          trajectory.push({
            timestampMs,
            frameIndex: f,
            frameHash: `loop_chunk_hash_${loopFrameIndex}`,
            keypoints: [],
            leftElbowAngleDeg: elbowAngle,
            rightElbowAngleDeg: elbowAngle,
            bodyAlignmentAngleDeg: 170
          });
        }
        break;
      }

      // Attack 4: Monitor Screen Recording
      case 'spoof_004_monitor_screen_recording': {
        for (let f = 0; f < totalFrames; f++) {
          const timestampMs = f * 150;
          const repPhase = (f % 6) / 6;
          const depth = Math.sin(repPhase * Math.PI);
          const elbowAngle = 165 - depth * 85;

          const data = createSynthesizedRgbFrame(0.30 + depth * 0.15, 0.40 + depth * 0.25);

          frames.push({
            timestampMs,
            frameIndex: f,
            frameHash: `monitor_frame_${Math.floor(f / 2)}`,
            width: 192,
            height: 192,
            data
          });

          trajectory.push({
            timestampMs,
            frameIndex: f,
            frameHash: `monitor_frame_${Math.floor(f / 2)}`,
            keypoints: [],
            leftElbowAngleDeg: elbowAngle,
            rightElbowAngleDeg: elbowAngle,
            bodyAlignmentAngleDeg: 170
          });
        }
        break;
      }

      // Attack 5: Temporal Timestamp Manipulation
      case 'spoof_005_temporal_inversion_jump': {
        for (let f = 0; f < totalFrames; f++) {
          // Non-monotonic backward timestamp jump
          const timestampMs = (totalFrames - f) * 150;
          const data = createSynthesizedRgbFrame(0.35, 0.45);

          frames.push({
            timestampMs,
            frameIndex: f,
            frameHash: `temporal_jump_${f}`,
            width: 192,
            height: 192,
            data
          });

          trajectory.push({
            timestampMs,
            frameIndex: f,
            frameHash: `temporal_jump_${f}`,
            keypoints: [],
            leftElbowAngleDeg: 120,
            rightElbowAngleDeg: 120,
            bodyAlignmentAngleDeg: 170
          });
        }
        break;
      }

      // Attack 6: Multi-Person / Non-Isolated Subject
      case 'spoof_006_crowded_room_multi_person': {
        for (let f = 0; f < totalFrames; f++) {
          const timestampMs = f * 150;
          const erraticAngle = 45 + ((f * 37) % 130);

          // Disjoint random noise blocks representing non-isolated chaotic motion
          const noiseData = new Uint8Array(192 * 192 * 3);
          for (let i = 0; i < noiseData.length; i += 7) {
            noiseData[i] = (f * 53 + i) % 256;
          }

          frames.push({
            timestampMs,
            frameIndex: f,
            frameHash: `crowded_room_${f}`,
            width: 192,
            height: 192,
            data: noiseData
          });

          trajectory.push({
            timestampMs,
            frameIndex: f,
            frameHash: `crowded_room_${f}`,
            keypoints: [],
            leftElbowAngleDeg: erraticAngle,
            rightElbowAngleDeg: 180 - erraticAngle,
            bodyAlignmentAngleDeg: 90 + (f % 50)
          });
        }
        break;
      }

      // Attack 7: Stale Replayed Evidence Nonce Mismatch
      case 'spoof_007_stale_replay_nonce_mismatch': {
        for (let f = 0; f < totalFrames; f++) {
          const timestampMs = f * 150;
          const repPhase = (f % 6) / 6;
          const depth = Math.sin(repPhase * Math.PI);
          const elbowAngle = 165 - depth * 85;

          const data = createSynthesizedRgbFrame(0.30 + depth * 0.15, 0.40 + depth * 0.25);

          frames.push({
            timestampMs,
            frameIndex: f,
            frameHash: `valid_stream_${f}`,
            width: 192,
            height: 192,
            data
          });

          trajectory.push({
            timestampMs,
            frameIndex: f,
            frameHash: `valid_stream_${f}`,
            keypoints: [],
            leftElbowAngleDeg: elbowAngle,
            rightElbowAngleDeg: elbowAngle,
            bodyAlignmentAngleDeg: 170
          });
        }
        break;
      }

      default:
        throw new Error(`Unknown adversarial fixture id: ${metadata.id}`);
    }

    return {
      metadata,
      frames,
      trajectory,
      sessionNonce
    };
  }
}
