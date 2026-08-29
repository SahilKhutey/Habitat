// Evaluate Achievements Use Case
import { AchievementEngine } from '../engine/achievement-engine';

export class EvaluateAchievementsUseCase {
  public static execute(userId: string) {
    return AchievementEngine.evaluateAchievements(userId);
  }
}
