// Adaptive Difficulty & Routine Health Foundation

export type AdaptationLevel = 'EASY' | 'STABLE' | 'CHALLENGING' | 'TOO_HARD';

export interface AdaptationRecommendation {
  taskTemplateId: string;
  taskName: string;
  currentDifficulty: number;
  completionRate: number;
  level: AdaptationLevel;
  recommendationType: 'INCREASE_CHALLENGE' | 'MAINTAIN' | 'SIMPLIFY_ROUTINE';
  message: string;
  proposedDifficulty?: number;
  userApprovalRequired: boolean;
}

export class AdaptationEngine {
  /**
   * Evaluates task performance and formulates non-coercive adaptation recommendations
   */
  public static evaluateTaskPerformance(params: {
    taskTemplateId: string;
    taskName: string;
    currentDifficulty: number;
    completedCount: number;
    assignedCount: number;
  }): AdaptationRecommendation {
    const rate = params.assignedCount > 0 ? (params.completedCount / params.assignedCount) * 100 : 100;

    let level: AdaptationLevel = 'STABLE';
    let recommendationType: 'INCREASE_CHALLENGE' | 'MAINTAIN' | 'SIMPLIFY_ROUTINE' = 'MAINTAIN';
    let message = 'Your discipline consistency is well balanced.';
    let proposedDifficulty = params.currentDifficulty;

    if (rate >= 95 && params.assignedCount >= 5) {
      level = 'EASY';
      recommendationType = 'INCREASE_CHALLENGE';
      proposedDifficulty = Math.min(5, params.currentDifficulty + 1);
      message = `You've consistently achieved a ${rate.toFixed(0)}% completion rate on "${params.taskName}". Ready to increase the challenge?`;
    } else if (rate < 40 && params.assignedCount >= 5) {
      level = 'TOO_HARD';
      recommendationType = 'SIMPLIFY_ROUTINE';
      proposedDifficulty = Math.max(1, params.currentDifficulty - 1);
      message = `"${params.taskName}" has proven challenging (${rate.toFixed(0)}% completion). Consider lowering difficulty or adjusting your timing.`;
    } else if (rate < 70) {
      level = 'CHALLENGING';
      recommendationType = 'MAINTAIN';
      message = `"${params.taskName}" is pushing your discipline edge (${rate.toFixed(0)}% completion). Keep building momentum.`;
    }

    return {
      taskTemplateId: params.taskTemplateId,
      taskName: params.taskName,
      currentDifficulty: params.currentDifficulty,
      completionRate: Number(rate.toFixed(1)),
      level,
      recommendationType,
      message,
      proposedDifficulty,
      userApprovalRequired: true
    };
  }
}
