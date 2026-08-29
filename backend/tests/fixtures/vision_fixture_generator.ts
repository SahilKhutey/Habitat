// Controlled Vision Fixture Generator: Valid, Invalid & Ambiguous Physical Exercise Benchmarks
import { VerificationEvidence, FramePoseRecord } from '../../src/modules/verification/domain/evidence.types';
import { SessionChallengeService } from '../../src/modules/proofs/services/session-challenge.service';

export interface VisionBenchmarkFixture {
  id: string;
  name: string;
  category: 'VALID' | 'INVALID' | 'AMBIGUOUS';
  expectedDecision: 'ACCEPT' | 'REVIEW' | 'REJECT';
  minimumExpectedReps?: number;
  description: string;
  evidence: VerificationEvidence;
}

export class VisionFixtureGenerator {
  /**
   * Generates genuine valid push-up benchmark fixtures
   */
  public static getValidFixtures(): VisionBenchmarkFixture[] {
    return [
      {
        id: 'pushups_good_01',
        name: '10 Strict Push-Ups (Standard Pace)',
        category: 'VALID',
        expectedDecision: 'ACCEPT',
        minimumExpectedReps: 10,
        description: '10 chest-to-floor repetitions with full 165 deg lockout and 80 deg bottom depth.',
        evidence: this.buildEvidence({
          totalReps: 10,
          framesPerRep: 30,
          lockoutAngle: 165,
          bottomAngle: 80,
          bodyAlignment: 170,
          meanConfidence: 0.96,
          livenessScore: 0.95
        })
      },
      {
        id: 'pushups_good_02',
        name: '12 Strict Push-Ups (Consistent Tempo)',
        category: 'VALID',
        expectedDecision: 'ACCEPT',
        minimumExpectedReps: 12,
        description: '12 chest-to-floor repetitions with solid biological velocity curves.',
        evidence: this.buildEvidence({
          totalReps: 12,
          framesPerRep: 28,
          lockoutAngle: 168,
          bottomAngle: 75,
          bodyAlignment: 168,
          meanConfidence: 0.97,
          livenessScore: 0.96
        })
      },
      {
        id: 'pushups_slow_01',
        name: '10 Slow Deliberate Push-Ups',
        category: 'VALID',
        expectedDecision: 'ACCEPT',
        minimumExpectedReps: 10,
        description: '10 deliberate reps with natural neuromuscular micro-tremors and biological duration.',
        evidence: this.buildEvidence({
          totalReps: 10,
          framesPerRep: 45,
          lockoutAngle: 162,
          bottomAngle: 85,
          bodyAlignment: 172,
          meanConfidence: 0.94,
          livenessScore: 0.92,
          addMicroTremor: true
        })
      }
    ];
  }

  /**
   * Generates invalid exercise benchmark fixtures
   */
  public static getInvalidFixtures(): VisionBenchmarkFixture[] {
    return [
      {
        id: 'insufficient_reps_01',
        name: 'Insufficient Repetitions (5 of 10 completed)',
        category: 'INVALID',
        expectedDecision: 'REJECT',
        minimumExpectedReps: 10,
        description: 'Only 5 valid repetitions completed, then resting in plank.',
        evidence: this.buildEvidence({
          totalReps: 5,
          framesPerRep: 30,
          lockoutAngle: 165,
          bottomAngle: 80,
          bodyAlignment: 170,
          trailingStaticFrames: 150,
          meanConfidence: 0.95,
          livenessScore: 0.85
        })
      },
      {
        id: 'incorrect_form_shallow_01',
        name: '10 Shallow Repetitions (No Chest Depth)',
        category: 'INVALID',
        expectedDecision: 'REJECT',
        minimumExpectedReps: 10,
        description: '10 shallow reps where elbow angles never descend below 115 deg (threshold <= 90 deg).',
        evidence: this.buildEvidence({
          totalReps: 10,
          framesPerRep: 30,
          lockoutAngle: 160,
          bottomAngle: 115, // Shallow!
          bodyAlignment: 165,
          meanConfidence: 0.94,
          livenessScore: 0.90
        })
      },
      {
        id: 'no_person_empty_room_01',
        name: 'Empty Room (No Person Detected)',
        category: 'INVALID',
        expectedDecision: 'REJECT',
        description: 'Camera recording static empty room with zero detected human keypoints.',
        evidence: this.buildEmptyEvidence()
      },
      {
        id: 'partial_body_occluded_01',
        name: 'Partial Body Occluded (Legs only, arms off-screen)',
        category: 'INVALID',
        expectedDecision: 'REJECT',
        description: 'Camera positioned where upper limbs and arms are outside frame.',
        evidence: this.buildEvidence({
          totalReps: 0,
          framesPerRep: 30,
          lockoutAngle: 180,
          bottomAngle: 180,
          bodyAlignment: 180,
          meanConfidence: 0.28,
          livenessScore: 0.35
        })
      }
    ];
  }

  /**
   * Generates ambiguous / edge-case fixtures requiring manual or secondary review
   */
  public static getAmbiguousFixtures(): VisionBenchmarkFixture[] {
    return [
      {
        id: 'low_light_noisy_01',
        name: 'Low Light / High Sensor Noise (10 Reps)',
        category: 'AMBIGUOUS',
        expectedDecision: 'REVIEW',
        minimumExpectedReps: 10,
        description: '10 valid reps performed in dark room (< 10 lux), high sensor noise, confidence ~0.48.',
        evidence: this.buildEvidence({
          totalReps: 10,
          framesPerRep: 30,
          lockoutAngle: 165,
          bottomAngle: 80,
          bodyAlignment: 165,
          meanConfidence: 0.48,
          livenessScore: 0.65
        })
      },
      {
        id: 'side_angle_steep_01',
        name: 'Steep 70-Degree Side Camera Angle',
        category: 'AMBIGUOUS',
        expectedDecision: 'REVIEW',
        minimumExpectedReps: 10,
        description: 'Steep acute side angle with periodic far-arm keypoint occlusion.',
        evidence: this.buildEvidence({
          totalReps: 10,
          framesPerRep: 30,
          lockoutAngle: 165,
          bottomAngle: 82,
          bodyAlignment: 160,
          meanConfidence: 0.58,
          livenessScore: 0.68
        })
      }
    ];
  }

  public static getAllBenchmarks(): VisionBenchmarkFixture[] {
    return [
      ...this.getValidFixtures(),
      ...this.getInvalidFixtures(),
      ...this.getAmbiguousFixtures()
    ];
  }

  private static buildEvidence(params: {
    totalReps: number;
    framesPerRep: number;
    lockoutAngle: number;
    bottomAngle: number;
    bodyAlignment: number;
    meanConfidence: number;
    livenessScore: number;
    trailingStaticFrames?: number;
    addMicroTremor?: boolean;
  }): VerificationEvidence {
    const trajectory: FramePoseRecord[] = [];
    let frameIdx = 0;

    for (let rep = 0; rep < params.totalReps; rep++) {
      for (let f = 0; f < params.framesPerRep; f++) {
        const progress = f / params.framesPerRep;
        const angleAmplitude = (params.lockoutAngle - params.bottomAngle) / 2;
        const baseAngle = params.bottomAngle + angleAmplitude * (1 + Math.cos(progress * 2 * Math.PI));
        const tremor = params.addMicroTremor ? (Math.sin(frameIdx * 1.7) * 1.5) : 0;
        const currentAngle = baseAngle + tremor;

        trajectory.push({
          timestampMs: frameIdx * 33,
          frameIndex: frameIdx,
          frameHash: `hash_${frameIdx}_rep${rep}`,
          keypoints: [],
          leftElbowAngleDeg: currentAngle,
          rightElbowAngleDeg: currentAngle,
          bodyAlignmentAngleDeg: params.bodyAlignment
        });
        frameIdx++;
      }
    }

    if (params.trailingStaticFrames) {
      for (let s = 0; s < params.trailingStaticFrames; s++) {
        trajectory.push({
          timestampMs: frameIdx * 33,
          frameIndex: frameIdx,
          frameHash: `hash_${frameIdx}_static`,
          keypoints: [],
          leftElbowAngleDeg: params.lockoutAngle,
          rightElbowAngleDeg: params.lockoutAngle,
          bodyAlignmentAngleDeg: params.bodyAlignment
        });
        frameIdx++;
      }
    }

    const challenge = SessionChallengeService.issueChallenge('benchmark-mission-1', 'benchmark-user');

    return {
      sessionId: challenge.sessionId,
      sessionNonce: challenge.sessionNonce,
      missionId: 'benchmark-mission-1',
      taskSlug: 'tpl-pushups-10',
      startedAt: new Date(Date.now() - frameIdx * 33).toISOString(),
      completedAt: new Date().toISOString(),
      durationMs: frameIdx * 33,
      pose: {
        model: 'MoveNet-Lightning',
        modelVersion: '1.0.0',
        totalFramesSampled: trajectory.length,
        meanPoseConfidence: params.meanConfidence,
        frameTrajectory: trajectory,
        repsCalculated: params.totalReps,
        shallowRepsCalculated: 0,
        stateTransitions: []
      },
      liveness: {
        livenessScore: params.livenessScore,
        temporalContinuityScore: 0.98,
        frameUniquenessScore: 0.98,
        trajectoryConsistencyScore: params.livenessScore,
        motionContinuityScore: 0.95,
        replayRiskScore: 1.0 - params.livenessScore,
        challengePassed: true
      },
      integrity: {
        clientAppVersion: '1.0.0',
        evidencePayloadHash: 'sha256_mock_benchmark_hash'
      }
    };
  }

  private static buildEmptyEvidence(): VerificationEvidence {
    const challenge = SessionChallengeService.issueChallenge('benchmark-mission-empty', 'benchmark-user');
    return {
      sessionId: challenge.sessionId,
      sessionNonce: challenge.sessionNonce,
      missionId: 'benchmark-mission-empty',
      taskSlug: 'tpl-pushups-10',
      startedAt: new Date(Date.now() - 10000).toISOString(),
      completedAt: new Date().toISOString(),
      durationMs: 10000,
      pose: {
        model: 'MoveNet-Lightning',
        modelVersion: '1.0.0',
        totalFramesSampled: 300,
        meanPoseConfidence: 0.04,
        frameTrajectory: Array.from({ length: 300 }, (_, i) => ({
          timestampMs: i * 33,
          frameIndex: i,
          frameHash: `empty_hash_${i}`,
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
        livenessScore: 0.05,
        temporalContinuityScore: 0.1,
        frameUniquenessScore: 0.1,
        trajectoryConsistencyScore: 0.0,
        motionContinuityScore: 0.0,
        replayRiskScore: 0.99,
        challengePassed: false
      },
      integrity: {
        clientAppVersion: '1.0.0',
        evidencePayloadHash: 'empty_hash'
      }
    };
  }
}
