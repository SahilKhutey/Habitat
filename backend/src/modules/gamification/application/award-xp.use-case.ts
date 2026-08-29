// Award XP Use Case (Idempotent & Immutable Ledger)
import { XpEngine } from '../engine/xp-engine';
import { GamificationRepository } from '../infrastructure/gamification.repository';
import { XPSourceType } from '../domain/xp.entity';

export interface AwardXpCommand {
  userId: string;
  amount: number;
  sourceType: XPSourceType;
  sourceId?: string;
  reason: string;
  idempotencyKey?: string;
}

export class AwardXpUseCase {
  public static execute(command: AwardXpCommand): { success: boolean; isDuplicate: boolean; totalXp: number } {
    if (command.idempotencyKey) {
      const existing = GamificationRepository.findXpByIdempotencyKey(command.idempotencyKey);
      if (existing) {
        return {
          success: true,
          isDuplicate: true,
          totalXp: GamificationRepository.sumTotalXp(command.userId)
        };
      }
    }

    const tx = XpEngine.awardXp(command);
    return {
      success: true,
      isDuplicate: false,
      totalXp: GamificationRepository.sumTotalXp(command.userId)
    };
  }
}
