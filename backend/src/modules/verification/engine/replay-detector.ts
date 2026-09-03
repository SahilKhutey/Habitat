// Dedicated Replay, Loop & Static Attack Detection Engine
import { Keypoint } from '../domain/evidence.types';

export interface ReplayFrameInput {
  frameIndex?: number;
  timestampMs: number;
  frameHash?: string;
  keypoints?: Keypoint[];
}

export interface ReplayDetectionResult {
  replayDetected: boolean;
  replayRiskScore: number; // 0.0 (clean) to 1.0 (certain spoof)
  reasons: string[];
  flags: string[];
  metrics: {
    uniquenessRatio: number;
    temporalViolations: number;
    loopScore: number;
    coordinateVariance: number;
  };
}

export class ReplayDetector {
  /**
   * Evaluates evidence against duplicate, loop, and static playback attack vectors
   */
  public static detect(frames: ReplayFrameInput[]): ReplayDetectionResult {
    const reasons: string[] = [];
    const flags: string[] = [];

    if (!frames || frames.length < 5) {
      return {
        replayDetected: true,
        replayRiskScore: 1.0,
        reasons: ['Insufficient frame sequence length for replay analysis (minimum 5 frames required).'],
        flags: ['INSUFFICIENT_FRAMES'],
        metrics: {
          uniquenessRatio: 0,
          temporalViolations: 0,
          loopScore: 1.0,
          coordinateVariance: 0
        }
      };
    }

    // 1. Frame Uniqueness & Static Frame Detection
    const hashes = frames.map((f) => f.frameHash).filter((h): h is string => Boolean(h));
    const uniqueHashes = new Set(hashes);
    const uniquenessRatio = hashes.length > 0 ? uniqueHashes.size / hashes.length : 1.0;

    let staticDetected = false;
    if (hashes.length >= 10 && uniqueHashes.size <= 2) {
      staticDetected = true;
      reasons.push('Static photograph or frozen video stream detected (no visual entropy across frames).');
      flags.push('STATIC_FRAME_SPOOF');
    } else if (hashes.length >= 20 && uniquenessRatio < 0.60) {
      reasons.push(`High frame duplication detected (uniqueness ratio: ${(uniquenessRatio * 100).toFixed(1)}%).`);
      flags.push('HIGH_FRAME_DUPLICATION');
    }

    // 2. Timestamp Monotonicity & Interval Continuity
    let temporalViolations = 0;
    for (let i = 1; i < frames.length; i++) {
      const dt = frames[i].timestampMs - frames[i - 1].timestampMs;
      if (dt <= 0) {
        temporalViolations += 2; // Duplicate or backwards timestamp
      } else if (dt > 3000) {
        temporalViolations += 1; // Unusually large timestamp gap
      }
    }

    if (temporalViolations >= 2) {
      reasons.push(`Abnormal timestamp progression detected (${temporalViolations} temporal violations).`);
      flags.push('TEMPORAL_MONOTONICITY_VIOLATION');
    }

    // 3. Periodic Loop Detection (Autocorrelation on frame hashes)
    let loopDetected = false;
    let loopScore = 0.0;

    if (hashes.length >= 20) {
      // Test for periodic loops of period lengths P from 5 to 20 frames
      const maxP = Math.min(20, Math.floor(hashes.length / 2));
      for (let p = 5; p <= maxP; p++) {
        let matches = 0;
        let comparisons = 0;
        for (let i = 0; i < hashes.length - p; i++) {
          if (hashes[i] === hashes[i + p]) {
            matches++;
          }
          comparisons++;
        }
        const matchRatio = comparisons > 0 ? matches / comparisons : 0;
        if (matchRatio > 0.80) {
          loopDetected = true;
          loopScore = matchRatio;
          reasons.push(`Periodic playback loop detected (cycle length: ${p} frames, periodicity match: ${(matchRatio * 100).toFixed(0)}%).`);
          flags.push('PERIODIC_VIDEO_LOOP');
          break;
        }
      }
    }

    // 4. Coordinate Variance Check (Micro-movement across keypoints)
    let coordinateVariance = 1.0;
    const framesWithKps = frames.filter((f) => f.keypoints && f.keypoints.length >= 17);

    if (framesWithKps.length >= 10) {
      const xCoords: number[] = [];
      const yCoords: number[] = [];

      for (const f of framesWithKps) {
        // Sample wrists and elbows
        for (const idx of [7, 8, 9, 10]) {
          const kp = f.keypoints![idx];
          if (kp && kp.x !== undefined && kp.y !== undefined) {
            xCoords.push(kp.x);
            yCoords.push(kp.y);
          }
        }
      }

      if (xCoords.length > 0) {
        const meanX = xCoords.reduce((a, b) => a + b, 0) / xCoords.length;
        const meanY = yCoords.reduce((a, b) => a + b, 0) / yCoords.length;
        const varX = xCoords.reduce((sum, x) => sum + Math.pow(x - meanX, 2), 0) / xCoords.length;
        const varY = yCoords.reduce((sum, y) => sum + Math.pow(y - meanY, 2), 0) / yCoords.length;
        coordinateVariance = Math.sqrt((varX + varY) / 2);

        // Natural human exercise exhibits landmark variance > 0.015
        if (coordinateVariance < 0.003 && framesWithKps.length >= 15) {
          reasons.push(`Unnatural pose stillness detected: landmark variance (${coordinateVariance.toFixed(4)}) indicates static image or still photo.`);
          flags.push('UNNATURAL_POSE_STILLNESS');
        }
      }
    }

    // 5. Replay Risk Score Synthesis (0.0 to 1.0)
    let replayRiskScore = 0.0;
    if (staticDetected) replayRiskScore += 0.95;
    if (loopDetected) replayRiskScore += 0.85;
    if (temporalViolations >= 2) replayRiskScore += 0.40;
    if (uniquenessRatio < 0.60) replayRiskScore += 0.50;
    if (coordinateVariance < 0.003 && framesWithKps.length >= 15) replayRiskScore += 0.70;

    replayRiskScore = Math.min(1.0, replayRiskScore);
    const replayDetected = replayRiskScore >= 0.50 || reasons.length > 0;

    return {
      replayDetected,
      replayRiskScore,
      reasons,
      flags,
      metrics: {
        uniquenessRatio,
        temporalViolations,
        loopScore,
        coordinateVariance
      }
    };
  }
}
