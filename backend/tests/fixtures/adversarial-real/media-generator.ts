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

export class AdversarialMediaGenerator {
  /**
   * Generates a concrete test fixture stream matching the ground-truth metadata specifications
   */
  public static generate(metadata: AdversarialFixtureMetadata): GeneratedFixtureData {
    const totalFrames = 220; // 10 reps @ 20 frames per rep + 20 lead/lag frames
    const frames: VisionFrame[] = [];
    const trajectory: FramePoseRecord[] = [];
    const sessionNonce = `challenge_nonce_${metadata.id}`;

    switch (metadata.id) {
      // 1. Genuine Controls
      case 'genuine_001_standard_pushups':
      case 'genuine_002_angled_pushups':
      case 'genuine_003_suboptimal_lighting': {
        const isDim = metadata.id === 'genuine_003_suboptimal_lighting';
        const baseLum = isDim ? 25 : 45;

        for (let f = 0; f < totalFrames; f++) {
          const timestampMs = f * 100;
          const repPhase = (f % 20) / 20;
          const depth = Math.sin(repPhase * Math.PI);
          // Biological micro-jitter (natural human movement)
          const jitter = (Math.sin(f * 1.7) + Math.cos(f * 2.3)) * 0.8;
          const elbowAngle = 165 - depth * 85 + jitter;

          const data = new Uint8Array(192 * 192 * 3);
          data.fill(baseLum + (f % 3));

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
        const staticData = new Uint8Array(192 * 192 * 3);
        staticData.fill(50);

        for (let f = 0; f < totalFrames; f++) {
          const timestampMs = f * 100;
          frames.push({
            timestampMs,
            frameIndex: f,
            frameHash: 'identical_static_frame_hash',
            width: 192,
            height: 192,
            data: staticData
          });

          trajectory.push({
            timestampMs,
            frameIndex: f,
            frameHash: 'identical_static_frame_hash',
            keypoints: [],
            leftElbowAngleDeg: 90, // Frozen perfectly at bottom
            rightElbowAngleDeg: 90,
            bodyAlignmentAngleDeg: 170
          });
        }
        break;
      }

      // Attack 2: Photo on Phone Screen
      case 'spoof_002_phone_screen_photo': {
        const screenData = new Uint8Array(192 * 192 * 3);
        screenData.fill(60);

        for (let f = 0; f < totalFrames; f++) {
          const timestampMs = f * 100;
          frames.push({
            timestampMs,
            frameIndex: f,
            frameHash: `screen_photo_${f % 2}`, // Slight optical flicker between 2 identical states
            width: 192,
            height: 192,
            data: screenData
          });

          trajectory.push({
            timestampMs,
            frameIndex: f,
            frameHash: `screen_photo_${f % 2}`,
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
          const loopFrameIndex = f % 20; // Exact identical 20-frame loop
          const timestampMs = f * 100;
          const repPhase = loopFrameIndex / 20;
          const depth = Math.sin(repPhase * Math.PI);
          const elbowAngle = 165 - depth * 85;

          const data = new Uint8Array(192 * 192 * 3);
          data.fill(40 + loopFrameIndex);

          frames.push({
            timestampMs,
            frameIndex: f,
            frameHash: `loop_chunk_hash_${loopFrameIndex}`, // Exact duplicate hash every cycle
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
          const timestampMs = f * 100;
          const repPhase = (f % 20) / 20;
          const depth = Math.sin(repPhase * Math.PI);
          const elbowAngle = 165 - depth * 85;

          // Low frame entropy due to monitor refresh capture
          const data = new Uint8Array(192 * 192 * 3);
          data.fill(55 + (f % 2));

          frames.push({
            timestampMs,
            frameIndex: f,
            frameHash: `monitor_frame_${Math.floor(f / 4)}`, // 4 repeated frames per step
            width: 192,
            height: 192,
            data
          });

          trajectory.push({
            timestampMs,
            frameIndex: f,
            frameHash: `monitor_frame_${Math.floor(f / 4)}`,
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
          // Anomalous timestamp jumps (e.g. 5000ms skip)
          const timestampMs = f < 50 ? f * 100 : f * 100 + 8000;
          const repPhase = (f % 20) / 20;
          const depth = Math.sin(repPhase * Math.PI);
          const elbowAngle = f === 50 ? 40 : 165 - depth * 85; // Unnatural teleportation jump

          const data = new Uint8Array(192 * 192 * 3);
          data.fill(45);

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
            leftElbowAngleDeg: elbowAngle,
            rightElbowAngleDeg: elbowAngle,
            bodyAlignmentAngleDeg: 170
          });
        }
        break;
      }

      // Attack 6: Multi-Person / Non-Isolated Subject
      case 'spoof_006_crowded_room_multi_person': {
        for (let f = 0; f < totalFrames; f++) {
          const timestampMs = f * 100;
          // Erratic angle changes caused by body tracking hopping between 2 people
          const elbowAngle = (f % 2 === 0) ? 165 : 75;

          const data = new Uint8Array(192 * 192 * 3);
          data.fill(40 + (f % 10));

          frames.push({
            timestampMs,
            frameIndex: f,
            frameHash: `multi_person_${f}`,
            width: 192,
            height: 192,
            data
          });

          trajectory.push({
            timestampMs,
            frameIndex: f,
            frameHash: `multi_person_${f}`,
            keypoints: [],
            leftElbowAngleDeg: elbowAngle,
            rightElbowAngleDeg: elbowAngle,
            bodyAlignmentAngleDeg: 110 // Bad form alignment
          });
        }
        break;
      }

      // Attack 7: Stale Replayed Evidence Nonce Mismatch
      case 'spoof_007_stale_replay_nonce_mismatch': {
        for (let f = 0; f < totalFrames; f++) {
          const timestampMs = f * 100;
          const repPhase = (f % 20) / 20;
          const depth = Math.sin(repPhase * Math.PI);
          const elbowAngle = 165 - depth * 85;

          const data = new Uint8Array(192 * 192 * 3);
          data.fill(45);

          frames.push({
            timestampMs,
            frameIndex: f,
            frameHash: `stale_proof_${f}`,
            width: 192,
            height: 192,
            data
          });

          trajectory.push({
            timestampMs,
            frameIndex: f,
            frameHash: `stale_proof_${f}`,
            keypoints: [],
            leftElbowAngleDeg: elbowAngle,
            rightElbowAngleDeg: elbowAngle,
            bodyAlignmentAngleDeg: 170
          });
        }
        break;
      }

      default:
        throw new Error(`Unknown fixture: ${metadata.id}`);
    }

    return {
      metadata,
      frames,
      trajectory,
      sessionNonce
    };
  }
}
