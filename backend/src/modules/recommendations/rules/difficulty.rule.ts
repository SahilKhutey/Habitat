// Difficulty Adaptation Rule
export interface DifficultyRuleInput {
  taskName: string;
  completionRate: number;
  sampleSize: number;
  currentDifficulty: number;
}

export class DifficultyRule {
  public static evaluate(input: DifficultyRuleInput) {
    if (input.sampleSize >= 5 && input.completionRate >= 95) {
      return {
        triggered: true,
        type: 'INCREASE_DIFFICULTY',
        title: `Increase Challenge: ${input.taskName}`,
        explanation: `You have completed ${input.taskName} ${input.completionRate.toFixed(0)}% of the time. Ready to increase the challenge?`,
        confidence: 0.90,
        suggestedDifficulty: Math.min(5, input.currentDifficulty + 1)
      };
    }

    if (input.sampleSize >= 5 && input.completionRate < 40) {
      return {
        triggered: true,
        type: 'REDUCE_DIFFICULTY',
        title: `Ease Load: ${input.taskName}`,
        explanation: `Completion rate is ${input.completionRate.toFixed(0)}%. Lowering difficulty will help restore consistent momentum.`,
        confidence: 0.85,
        suggestedDifficulty: Math.max(1, input.currentDifficulty - 1)
      };
    }

    return { triggered: false };
  }
}
