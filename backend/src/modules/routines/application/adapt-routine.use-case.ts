// Adapt Routine Application Use Case
import { AdaptationEngine, AdaptationRecommendation } from '../engine/adaptation-engine';

export class AdaptRoutineUseCase {
  public static execute(params: {
    taskTemplateId: string;
    taskName: string;
    currentDifficulty: number;
    completedCount: number;
    assignedCount: number;
  }): AdaptationRecommendation {
    return AdaptationEngine.evaluateTaskPerformance(params);
  }
}
