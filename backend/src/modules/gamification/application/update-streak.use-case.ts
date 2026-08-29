// Update Streak Use Case (Timezone & Minimum Daily Commitment Aware)
import { StreakEngine } from '../engine/streak-engine';

export interface UpdateStreakCommand {
  userId: string;
  timezone?: string;
}

export class UpdateStreakUseCase {
  public static execute(command: UpdateStreakCommand) {
    return StreakEngine.updateStreak(command.userId, command.timezone || 'UTC');
  }
}
