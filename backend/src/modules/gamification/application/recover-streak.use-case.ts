// Streak Recovery Use Case (Preserves Streak Without Falsifying Mission Truth)
import { StreakEngine } from '../engine/streak-engine';

export class RecoverStreakUseCase {
  public static execute(userId: string) {
    return StreakEngine.recoverStreak(userId);
  }
}
