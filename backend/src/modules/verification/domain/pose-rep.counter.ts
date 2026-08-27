// Action & Pose Estimation Repetition Counting Evaluator

export class PoseRepCounter {
  /**
   * Evaluates detected motion cycles and repetitions for exercise missions
   */
  public static evaluateRepetitions(
    detectedReps: number,
    requiredReps: number,
    poseConfidence: number = 0.90
  ): {
    passed: boolean;
    repsCounted: number;
    requiredReps: number;
    confidence: number;
    rejectionReason: string | null;
  } {
    if (detectedReps >= requiredReps) {
      return {
        passed: true,
        repsCounted: detectedReps,
        requiredReps,
        confidence: Math.min(1.0, poseConfidence),
        rejectionReason: null
      };
    }

    return {
      passed: false,
      repsCounted: detectedReps,
      requiredReps,
      confidence: Math.max(0.3, poseConfidence * (detectedReps / requiredReps)),
      rejectionReason: `Insufficient repetitions detected (${detectedReps}/${requiredReps} reps completed). Complete full range of motion.`
    };
  }
}
