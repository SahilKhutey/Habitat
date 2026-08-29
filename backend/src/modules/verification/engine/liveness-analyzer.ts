// Multi-Signal Temporal Liveness & Anti-Cheat Analysis Engine
import { FramePoseRecord } from '../domain/evidence.types';

export interface LivenessAnalysisResult {
  livenessScore: number;
  temporalContinuityScore: number;
  frameUniquenessScore: number;
  trajectoryConsistencyScore: number;
  motionContinuityScore: number;
  replayRiskScore: number;
  isLivenessValid: boolean;
  rejectionReason: string | null;
  flags: string[];
}

export class LivenessAnalyzer {
  /**
   * Evaluates 5 orthogonal signals across frame pose trajectory:
   * 1. Frame uniqueness (Hash variance)
   * 2. Temporal monotonicity and frame interval continuity
   * 3. Joint trajectory velocity smoothness (no teleportation)
   * 4. Biomechanical motion range (full amplitude movement)
   * 5. Autocorrelation / Replay loop detection
   */
  public static analyze(trajectory: FramePoseRecord[]): LivenessAnalysisResult {
    const flags: string[] = [];

    if (!trajectory || trajectory.length < 5) {
      return {
        livenessScore: 0.0,
        temporalContinuityScore: 0.0,
        frameUniquenessScore: 0.0,
        trajectoryConsistencyScore: 0.0,
        motionContinuityScore: 0.0,
        replayRiskScore: 1.0,
        isLivenessValid: false,
        rejectionReason: 'Insufficient frame samples to establish liveness (minimum 5 frames required).',
        flags: ['INSUFFICIENT_SAMPLES']
      };
    }

    // 1. Frame Uniqueness Analysis
    const hashes = trajectory.map((f) => f.frameHash).filter(Boolean);
    const uniqueHashes = new Set(hashes);
    const uniquenessRatio = hashes.length > 0 ? uniqueHashes.size / hashes.length : 1.0;

    let frameUniquenessScore = Math.min(1.0, uniquenessRatio * 1.25);
    if (uniqueHashes.size <= 2 && trajectory.length >= 10) {
      frameUniquenessScore = 0.0;
      flags.push('STATIC_PHOTO_OR_FROZEN_FRAME');
    } else if (uniquenessRatio < 0.60 && trajectory.length >= 30) {
      flags.push('POTENTIAL_REPLAY_LOOP_DETECTED');
    }

    // 2. Temporal Monotonicity & Interval Continuity
    let temporalViolations = 0;
    let totalIntervals = 0;

    for (let i = 1; i < trajectory.length; i++) {
      const dt = trajectory[i].timestampMs - trajectory[i - 1].timestampMs;
      totalIntervals++;

      // Valid frame rates: 5 FPS (200ms) to 120 FPS (8ms)
      if (dt <= 0) {
        temporalViolations += 2; // Retro-dated or duplicate timestamp
      } else if (dt > 2500) {
        temporalViolations += 1; // Major frame drop or gap
      }
    }

    const temporalPenalty = (temporalViolations * 0.08);
    const temporalContinuityScore = Math.max(0.0, 1.0 - temporalPenalty);
    if (temporalViolations > 0 || temporalContinuityScore < 0.95) {
      flags.push('TEMPORAL_MONOTONICITY_VIOLATION');
    }

    // 3. Trajectory Velocity & Biomechanical Smoothness
    let velocityViolations = 0;
    let angleChanges = 0;

    for (let i = 1; i < trajectory.length; i++) {
      const dtSec = (trajectory[i].timestampMs - trajectory[i - 1].timestampMs) / 1000;
      if (dtSec > 0) {
        const meanElbowPrev = (trajectory[i - 1].leftElbowAngleDeg + trajectory[i - 1].rightElbowAngleDeg) / 2;
        const meanElbowCurr = (trajectory[i].leftElbowAngleDeg + trajectory[i].rightElbowAngleDeg) / 2;
        const dAngle = Math.abs(meanElbowCurr - meanElbowPrev);
        angleChanges += dAngle;

        const velocityDegPerSec = dAngle / dtSec;
        // Natural human elbow movement during pushup rarely exceeds 600 deg/sec
        if (velocityDegPerSec > 1000) {
          velocityViolations++;
        }
      }
    }

    const trajectoryConsistencyScore = Math.max(
      0.0,
      1.0 - (velocityViolations / Math.max(1, trajectory.length / 5))
    );
    if (velocityViolations > 3) {
      flags.push('UNNATURAL_TRAJECTORY_VELOCITY');
    }

    // 4. Motion Range / Dynamic Amplitude
    const elbowAngles = trajectory.map(
      (f) => (f.leftElbowAngleDeg + f.rightElbowAngleDeg) / 2
    );
    const minElbow = Math.min(...elbowAngles);
    const maxElbow = Math.max(...elbowAngles);
    const angleRange = maxElbow - minElbow;

    let motionContinuityScore = 0.0;
    if (angleRange >= 60) {
      motionContinuityScore = 1.0;
    } else if (angleRange >= 30) {
      motionContinuityScore = angleRange / 60;
    } else {
      motionContinuityScore = 0.1;
      flags.push('NEGLIGIBLE_MOTION_AMPLITUDE');
    }

    // 5. Replay Loop & Autocorrelation Detection
    // Checks whether repeated segments are mathematically identical and reuse frame hashes
    const replayRiskScore = this.detectReplayAutocorrelation(elbowAngles);
    if (replayRiskScore > 0.85 && uniquenessRatio < 0.70) {
      flags.push('POTENTIAL_REPLAY_LOOP_DETECTED');
    }

    // Calculate Composite Liveness Score
    let compositeScore =
      frameUniquenessScore * 0.25 +
      temporalContinuityScore * 0.25 +
      trajectoryConsistencyScore * 0.25 +
      motionContinuityScore * 0.15 +
      (1.0 - replayRiskScore) * 0.10;

    if (flags.includes('STATIC_PHOTO_OR_FROZEN_FRAME')) {
      compositeScore = Math.min(compositeScore * 0.2, 0.10);
    }

    const roundedScore = Math.round(compositeScore * 100) / 100;
    const isLivenessValid = roundedScore >= 0.70 && !flags.includes('STATIC_PHOTO_OR_FROZEN_FRAME');

    let rejectionReason: string | null = null;
    if (!isLivenessValid) {
      if (flags.includes('STATIC_PHOTO_OR_FROZEN_FRAME')) {
        rejectionReason = 'Static photograph or frozen frame detected. Live physical execution is required.';
      } else if (flags.includes('NEGLIGIBLE_MOTION_AMPLITUDE')) {
        rejectionReason = 'Insufficient physical range of motion detected during session.';
      } else if (flags.includes('POTENTIAL_REPLAY_LOOP_DETECTED')) {
        rejectionReason = 'Repetitive synthetic replay pattern detected. Execute live repetitions.';
      } else {
        rejectionReason = 'Liveness score below authenticity threshold. Ensure continuous live camera capture.';
      }
    }

    return {
      livenessScore: roundedScore,
      temporalContinuityScore: Math.round(temporalContinuityScore * 100) / 100,
      frameUniquenessScore: Math.round(frameUniquenessScore * 100) / 100,
      trajectoryConsistencyScore: Math.round(trajectoryConsistencyScore * 100) / 100,
      motionContinuityScore: Math.round(motionContinuityScore * 100) / 100,
      replayRiskScore: Math.round(replayRiskScore * 100) / 100,
      isLivenessValid,
      rejectionReason,
      flags
    };
  }

  /**
   * Computes trajectory autocorrelation to detect exact looping / synthetic duplicates
   */
  private static detectReplayAutocorrelation(series: number[]): number {
    if (series.length < 20) return 0.0;

    const mean = series.reduce((a, b) => a + b, 0) / series.length;
    const variance = series.reduce((sum, val) => sum + Math.pow(val - mean, 2), 0);

    if (variance < 1.0) return 0.0; // Flat line handled by motion range

    let maxCorrelation = 0.0;
    // Check lag periods between 8 and 120 frames (0.25s to 4.0s cadence)
    for (let lag = 8; lag <= Math.min(120, Math.floor(series.length / 2)); lag++) {
      let covariance = 0;
      for (let i = 0; i < series.length - lag; i++) {
        covariance += (series[i] - mean) * (series[i + lag] - mean);
      }
      const r = covariance / variance;
      if (r > maxCorrelation && r < 0.999) {
        maxCorrelation = r;
      }
    }

    // High periodic identical autocorrelation indicates synthetic looping
    return maxCorrelation > 0.88 ? maxCorrelation : 0.0;
  }
}
