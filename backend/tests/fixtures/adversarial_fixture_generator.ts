// Adversarial & Anti-Spoofing Attack Corpus Generator
import { VerificationEvidence, FramePoseRecord } from '../../src/modules/verification/domain/evidence.types';

export interface AdversarialFixture {
  attackId: string;
  attackName: string;
  threatModel: string;
  expectedDecision: 'REJECT' | 'REVIEW'; // Spoofs MUST NEVER return ACCEPT!
  evidence: VerificationEvidence;
}

export class AdversarialFixtureGenerator {
  /**
   * Attack 1: Static Photograph Broadcast
   * A single printed photo or frozen frame broadcast over 300 frames.
   */
  public static getStaticPhotoAttack(): AdversarialFixture {
    const identicalHash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
    const trajectory: FramePoseRecord[] = Array.from({ length: 300 }, (_, i) => ({
      timestampMs: i * 33,
      frameIndex: i,
      frameHash: identicalHash, // Frozen hash!
      keypoints: [],
      leftElbowAngleDeg: 165,
      rightElbowAngleDeg: 165,
      bodyAlignmentAngleDeg: 170
    }));

    return {
      attackId: 'attack_01_static_photo',
      attackName: 'Static Photograph Presentation',
      threatModel: 'Attacker points camera at a printed photograph of a person holding pushup stance.',
      expectedDecision: 'REJECT',
      evidence: {
        sessionId: 'sess_atk_1',
        sessionNonce: 'mock_atk1_nonce',
        missionId: 'atk-mission-1',
        taskSlug: 'tpl-pushups-10',
        startedAt: new Date(Date.now() - 10000).toISOString(),
        completedAt: new Date().toISOString(),
        durationMs: 10000,
        pose: {
          model: 'MoveNet-Lightning',
          modelVersion: '1.0.0',
          totalFramesSampled: 300,
          meanPoseConfidence: 0.95,
          frameTrajectory: trajectory,
          repsCalculated: 0,
          shallowRepsCalculated: 0,
          stateTransitions: []
        },
        liveness: {
          livenessScore: 0.05,
          temporalContinuityScore: 1.0,
          frameUniquenessScore: 0.0, // Frozen!
          trajectoryConsistencyScore: 0.0,
          motionContinuityScore: 0.0,
          replayRiskScore: 0.99,
          challengePassed: false
        },
        integrity: {
          clientAppVersion: '1.0.0',
          evidencePayloadHash: identicalHash
        }
      }
    };
  }

  /**
   * Attack 2: Photo Displayed on Another Phone Screen
   */
  public static getPhotoScreenDisplayAttack(): AdversarialFixture {
    const trajectory: FramePoseRecord[] = Array.from({ length: 300 }, (_, i) => ({
      timestampMs: i * 33,
      frameIndex: i,
      frameHash: `screen_hash_${i % 4}`, // Cyclic screen flicker
      keypoints: [],
      leftElbowAngleDeg: 160 + (i % 2 === 0 ? 0.2 : -0.2), // Micro planar jitter
      rightElbowAngleDeg: 160 + (i % 2 === 0 ? 0.2 : -0.2),
      bodyAlignmentAngleDeg: 168
    }));

    return {
      attackId: 'attack_02_phone_screen_display',
      attackName: 'Photo on Smartphone Screen',
      threatModel: 'Attacker holds up a phone showing an image of pushups with slight camera shake.',
      expectedDecision: 'REJECT',
      evidence: {
        sessionId: 'sess_atk_2',
        sessionNonce: 'mock_atk2_nonce',
        missionId: 'atk-mission-2',
        taskSlug: 'tpl-pushups-10',
        startedAt: new Date(Date.now() - 10000).toISOString(),
        completedAt: new Date().toISOString(),
        durationMs: 10000,
        pose: {
          model: 'MoveNet-Lightning',
          modelVersion: '1.0.0',
          totalFramesSampled: 300,
          meanPoseConfidence: 0.91,
          frameTrajectory: trajectory,
          repsCalculated: 0,
          shallowRepsCalculated: 0,
          stateTransitions: []
        },
        liveness: {
          livenessScore: 0.12,
          temporalContinuityScore: 0.4,
          frameUniquenessScore: 0.1,
          trajectoryConsistencyScore: 0.05,
          motionContinuityScore: 0.1,
          replayRiskScore: 0.95,
          challengePassed: false
        },
        integrity: {
          clientAppVersion: '1.0.0',
          evidencePayloadHash: 'screen_atk_hash'
        }
      }
    };
  }

  /**
   * Attack 3: Looped Video Replay (Repeating Pushup Loop)
   */
  public static getLoopedVideoAttack(): AdversarialFixture {
    const loopUnits: FramePoseRecord[] = [];
    // Single 2-rep segment (60 frames)
    for (let f = 0; f < 60; f++) {
      const progress = f / 30;
      const angle = 120 + 45 * Math.cos(progress * 2 * Math.PI);
      loopUnits.push({
        timestampMs: f * 33,
        frameIndex: f,
        frameHash: `loop_unit_hash_${f}`,
        keypoints: [],
        leftElbowAngleDeg: angle,
        rightElbowAngleDeg: angle,
        bodyAlignmentAngleDeg: 170
      });
    }

    // Duplicate the 60 frames 5 times (300 frames total, perfect loop replay)
    const trajectory: FramePoseRecord[] = [];
    for (let loop = 0; loop < 5; loop++) {
      for (let f = 0; f < 60; f++) {
        const idx = loop * 60 + f;
        trajectory.push({
          ...loopUnits[f],
          timestampMs: idx * 33,
          frameIndex: idx,
          frameHash: loopUnits[f].frameHash // Repeating hashes!
        });
      }
    }

    return {
      attackId: 'attack_03_looped_video_replay',
      attackName: 'Looped Video Replay (3 reps looped to 10)',
      threatModel: 'Attacker records 2 reps and loops the video file 5 times to fake 10 reps.',
      expectedDecision: 'REJECT',
      evidence: {
        sessionId: 'sess_atk_3',
        sessionNonce: 'mock_atk3_nonce',
        missionId: 'atk-mission-3',
        taskSlug: 'tpl-pushups-10',
        startedAt: new Date(Date.now() - 10000).toISOString(),
        completedAt: new Date().toISOString(),
        durationMs: 10000,
        pose: {
          model: 'MoveNet-Lightning',
          modelVersion: '1.0.0',
          totalFramesSampled: 300,
          meanPoseConfidence: 0.95,
          frameTrajectory: trajectory,
          repsCalculated: 10,
          shallowRepsCalculated: 0,
          stateTransitions: []
        },
        liveness: {
          livenessScore: 0.20,
          temporalContinuityScore: 0.9,
          frameUniquenessScore: 0.2, // Low uniqueness due to exact repeating hashes
          trajectoryConsistencyScore: 0.9,
          motionContinuityScore: 0.9,
          replayRiskScore: 0.98, // Autocorrelation flag!
          challengePassed: false
        },
        integrity: {
          clientAppVersion: '1.0.0',
          evidencePayloadHash: 'loop_atk_hash'
        }
      }
    };
  }

  /**
   * Attack 4: Screen Recording / Monitor Playback
   */
  public static getScreenRecordingAttack(): AdversarialFixture {
    const trajectory: FramePoseRecord[] = Array.from({ length: 300 }, (_, i) => {
      const isDropped = i % 15 === 0; // Cadence stutter
      const angle = isDropped ? 140 : (120 + 45 * Math.cos(((i % 30) / 30) * 2 * Math.PI));
      return {
        timestampMs: i * 33 + (isDropped ? 150 : 0),
        frameIndex: i,
        frameHash: `screen_rec_hash_${i}`,
        keypoints: [],
        leftElbowAngleDeg: angle,
        rightElbowAngleDeg: angle,
        bodyAlignmentAngleDeg: 165
      };
    });

    return {
      attackId: 'attack_04_screen_recording',
      attackName: 'Screen Recording Playback',
      threatModel: 'Attacker plays a pre-recorded YouTube workout on laptop and points phone at screen.',
      expectedDecision: 'REJECT',
      evidence: {
        sessionId: 'sess_atk_4',
        sessionNonce: 'mock_atk4_nonce',
        missionId: 'atk-mission-4',
        taskSlug: 'tpl-pushups-10',
        startedAt: new Date(Date.now() - 10000).toISOString(),
        completedAt: new Date().toISOString(),
        durationMs: 10000,
        pose: {
          model: 'MoveNet-Lightning',
          modelVersion: '1.0.0',
          totalFramesSampled: 300,
          meanPoseConfidence: 0.85,
          frameTrajectory: trajectory,
          repsCalculated: 10,
          shallowRepsCalculated: 0,
          stateTransitions: []
        },
        liveness: {
          livenessScore: 0.35,
          temporalContinuityScore: 0.4,
          frameUniquenessScore: 0.8,
          trajectoryConsistencyScore: 0.5,
          motionContinuityScore: 0.4,
          replayRiskScore: 0.85,
          challengePassed: false
        },
        integrity: {
          clientAppVersion: '1.0.0',
          evidencePayloadHash: 'screen_rec_hash'
        }
      }
    };
  }

  /**
   * Attack 5: Temporal Manipulation (Dropped / Fast-Forward Frames)
   */
  public static getTemporalManipulationAttack(): AdversarialFixture {
    // Non-monotonic frame timestamps
    const trajectory: FramePoseRecord[] = Array.from({ length: 150 }, (_, i) => {
      const jumpedTime = i === 50 ? (i * 33 - 500) : (i * 66); // Backward time jump!
      return {
        timestampMs: jumpedTime,
        frameIndex: i,
        frameHash: `temp_manip_${i}`,
        keypoints: [],
        leftElbowAngleDeg: 120 + 45 * Math.cos(((i % 15) / 15) * 2 * Math.PI),
        rightElbowAngleDeg: 120 + 45 * Math.cos(((i % 15) / 15) * 2 * Math.PI),
        bodyAlignmentAngleDeg: 170
      };
    });

    return {
      attackId: 'attack_05_temporal_manipulation',
      attackName: 'Temporal Jumps & Frame Splicing',
      threatModel: 'Attacker splices clips together causing non-monotonic timestamps and velocity spikes.',
      expectedDecision: 'REJECT',
      evidence: {
        sessionId: 'sess_atk_5',
        sessionNonce: 'mock_atk5_nonce',
        missionId: 'atk-mission-5',
        taskSlug: 'tpl-pushups-10',
        startedAt: new Date(Date.now() - 5000).toISOString(),
        completedAt: new Date().toISOString(),
        durationMs: 5000,
        pose: {
          model: 'MoveNet-Lightning',
          modelVersion: '1.0.0',
          totalFramesSampled: 150,
          meanPoseConfidence: 0.92,
          frameTrajectory: trajectory,
          repsCalculated: 10,
          shallowRepsCalculated: 0,
          stateTransitions: []
        },
        liveness: {
          livenessScore: 0.15,
          temporalContinuityScore: 0.0, // Non-monotonic flag!
          frameUniquenessScore: 0.9,
          trajectoryConsistencyScore: 0.2,
          motionContinuityScore: 0.1,
          replayRiskScore: 0.9,
          challengePassed: false
        },
        integrity: {
          clientAppVersion: '1.0.0',
          evidencePayloadHash: 'temp_manip_hash'
        }
      }
    };
  }

  /**
   * Attack 6: Multiple People in Camera View
   */
  public static getMultiplePeopleAttack(): AdversarialFixture {
    return {
      attackId: 'attack_06_multiple_people',
      attackName: 'Multiple People Collision',
      threatModel: 'Two people attempting exercises in front of camera, causing keypoint collision.',
      expectedDecision: 'REVIEW',
      evidence: {
        sessionId: 'sess_atk_6',
        sessionNonce: 'mock_atk6_nonce',
        missionId: 'atk-mission-6',
        taskSlug: 'tpl-pushups-10',
        startedAt: new Date(Date.now() - 10000).toISOString(),
        completedAt: new Date().toISOString(),
        durationMs: 10000,
        pose: {
          model: 'MoveNet-Lightning',
          modelVersion: '1.0.0',
          totalFramesSampled: 300,
          meanPoseConfidence: 0.55,
          frameTrajectory: Array.from({ length: 300 }, (_, i) => ({
            timestampMs: i * 33,
            frameIndex: i,
            frameHash: `multi_person_${i}`,
            keypoints: [],
            leftElbowAngleDeg: 120 + 35 * Math.cos(((i % 30) / 30) * 2 * Math.PI),
            rightElbowAngleDeg: 120 + 35 * Math.cos(((i % 30) / 30) * 2 * Math.PI),
            bodyAlignmentAngleDeg: 155
          })),
          repsCalculated: 8,
          shallowRepsCalculated: 2,
          stateTransitions: []
        },
        liveness: {
          livenessScore: 0.52,
          temporalContinuityScore: 0.7,
          frameUniquenessScore: 0.8,
          trajectoryConsistencyScore: 0.5,
          motionContinuityScore: 0.6,
          replayRiskScore: 0.4,
          challengePassed: true
        },
        integrity: {
          clientAppVersion: '1.0.0',
          evidencePayloadHash: 'multi_person_hash'
        }
      }
    };
  }

  /**
   * Attack 7: Camera Pointed at Ceiling / Static Background
   */
  public static getCeilingPointedAttack(): AdversarialFixture {
    return {
      attackId: 'attack_07_ceiling_pointed',
      attackName: 'Camera Pointed at Ceiling',
      threatModel: 'Attacker points camera at ceiling and mimics exercise noises.',
      expectedDecision: 'REJECT',
      evidence: {
        sessionId: 'sess_atk_7',
        sessionNonce: 'mock_atk7_nonce',
        missionId: 'atk-mission-7',
        taskSlug: 'tpl-pushups-10',
        startedAt: new Date(Date.now() - 10000).toISOString(),
        completedAt: new Date().toISOString(),
        durationMs: 10000,
        pose: {
          model: 'MoveNet-Lightning',
          modelVersion: '1.0.0',
          totalFramesSampled: 300,
          meanPoseConfidence: 0.08,
          frameTrajectory: Array.from({ length: 300 }, (_, i) => ({
            timestampMs: i * 33,
            frameIndex: i,
            frameHash: `ceiling_${i}`,
            keypoints: [],
            leftElbowAngleDeg: 0,
            rightElbowAngleDeg: 0,
            bodyAlignmentAngleDeg: 0
          })),
          repsCalculated: 0,
          shallowRepsCalculated: 0,
          stateTransitions: []
        },
        liveness: {
          livenessScore: 0.02,
          temporalContinuityScore: 0.2,
          frameUniquenessScore: 0.1,
          trajectoryConsistencyScore: 0.0,
          motionContinuityScore: 0.0,
          replayRiskScore: 0.99,
          challengePassed: false
        },
        integrity: {
          clientAppVersion: '1.0.0',
          evidencePayloadHash: 'ceiling_hash'
        }
      }
    };
  }

  public static getAllAdversarialAttacks(): AdversarialFixture[] {
    return [
      this.getStaticPhotoAttack(),
      this.getPhotoScreenDisplayAttack(),
      this.getLoopedVideoAttack(),
      this.getScreenRecordingAttack(),
      this.getTemporalManipulationAttack(),
      this.getMultiplePeopleAttack(),
      this.getCeilingPointedAttack()
    ];
  }
}
