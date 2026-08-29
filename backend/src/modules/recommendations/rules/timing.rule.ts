// Timing, Overload, Recovery, and Consistency Rules
export class TimingRule {
  public static evaluate(params: {
    taskName: string;
    morningRate: number;
    eveningRate: number;
    sampleSize: number;
  }) {
    if (params.sampleSize >= 5 && params.morningRate >= 85 && params.eveningRate <= 50) {
      return {
        triggered: true,
        type: 'MOVE_TASK',
        title: `Optimize Timing: ${params.taskName}`,
        explanation: `You complete this task with ${params.morningRate.toFixed(0)}% consistency in the morning vs ${params.eveningRate.toFixed(0)}% in the evening. Moving it earlier will help maintain momentum.`,
        confidence: 0.88
      };
    }
    return { triggered: false };
  }
}

export class OverloadRule {
  public static evaluate(params: {
    dailyTaskCount: number;
    estimatedDurationMinutes: number;
    completionRate: number;
  }) {
    if (params.dailyTaskCount >= 10 && params.completionRate < 50) {
      return {
        triggered: true,
        type: 'SIMPLIFY_ROUTINE',
        title: 'Streamline Daily Routine',
        explanation: `Your routine currently includes ${params.dailyTaskCount} tasks totaling ${params.estimatedDurationMinutes} minutes. Streamlining to 3-5 core habit anchors will rebuild consistent follow-through.`,
        confidence: 0.92
      };
    }
    return { triggered: false };
  }
}

export class RecoveryRule {
  public static evaluate(params: {
    recentMissCount: number;
    streakBroken: boolean;
  }) {
    if (params.recentMissCount >= 3 || params.streakBroken) {
      return {
        triggered: true,
        type: 'RECOVER',
        title: 'Momentum Recovery Mode',
        explanation: 'Focus on 1 essential habit anchor today to rebuild momentum without anxiety.',
        confidence: 0.86
      };
    }
    return { triggered: false };
  }
}

export class ConsistencyRule {
  public static evaluate(params: {
    completionRate: number;
    streakDays: number;
  }) {
    if (params.streakDays >= 14 && params.completionRate >= 90) {
      return {
        triggered: true,
        type: 'MAINTAIN',
        title: 'Strong Consistency Baseline',
        explanation: 'Your discipline habits are running with high stability. Maintain current cadence.',
        confidence: 0.95
      };
    }
    return { triggered: false };
  }
}
