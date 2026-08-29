// Calculate Rolling Discipline Score Use Case
import { ScoreEngine } from '../engine/score-engine';

export class CalculateScoreUseCase {
  public static execute(userId: string, windowDays: number = 30) {
    return ScoreEngine.calculateDisciplineScore(userId, windowDays);
  }
}
