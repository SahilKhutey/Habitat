// Analyze Task & Detect Patterns Use Cases
import { BehaviorEngine } from '../engine/behavior-engine';
import { PatternEngine } from '../../intelligence/engine/pattern-engine';

export class AnalyzeTaskUseCase {
  public static execute(userId: string, taskId: string, startDate?: Date, endDate?: Date) {
    const end = endDate || new Date();
    const start = startDate || new Date(end.getTime() - 30 * 24 * 60 * 60 * 1000);

    return BehaviorEngine.calculateTaskPerformance({
      userId,
      taskTemplateId: taskId,
      startDate: start,
      endDate: end
    });
  }
}

export class DetectPatternsUseCase {
  public static execute(userId: string) {
    return PatternEngine.discoverPatterns(userId);
  }
}
