// Ranking & Explanation Engines for Recommendations
import { RecommendationEntity } from '../domain/recommendation.entity';

export class RankingEngine {
  /**
   * Ranks recommendation candidates by priority weight, confidence, and urgency; caps display at top N
   */
  public static rankRecommendations(recommendations: RecommendationEntity[], limit: number = 3): RecommendationEntity[] {
    const priorityWeights: Record<string, number> = {
      CRITICAL: 4.0,
      HIGH: 3.0,
      MEDIUM: 2.0,
      LOW: 1.0
    };

    return [...recommendations]
      .sort((a, b) => {
        const weightA = (priorityWeights[a.priority] || 1) * a.confidence;
        const weightB = (priorityWeights[b.priority] || 1) * b.confidence;
        return weightB - weightA;
      })
      .slice(0, limit);
  }
}

export class ExplanationEngine {
  /**
   * Generates clear, non-judgmental explanations without psychological assumptions
   */
  public static formatExplanation(type: string, data: { taskName?: string; rate?: number; diff?: number }): string {
    switch (type) {
      case 'INCREASE_DIFFICULTY':
        return `You have completed "${data.taskName}" consistently (${data.rate?.toFixed(0)}%). Increasing the challenge slightly keeps neuromuscular adaptation active.`;
      case 'REDUCE_DIFFICULTY':
        return `"${data.taskName}" currently shows lower completion. Reducing requirements temporarily helps build unbroken momentum.`;
      case 'MOVE_TASK':
        return `Data indicates higher follow-through during morning focus windows.`;
      default:
        return 'Maintaining your current routine provides the strongest consistency.';
    }
  }
}
