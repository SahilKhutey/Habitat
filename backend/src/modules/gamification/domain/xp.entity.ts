// Immutable XP Ledger Transaction Entity

export type XPSourceType =
  | 'MISSION_COMPLETION'
  | 'ACHIEVEMENT'
  | 'STREAK_BONUS'
  | 'RECOVERY'
  | 'ADMIN_ADJUSTMENT';

export interface XPTransactionEntity {
  id: string;
  userId: string;
  amount: number;
  sourceType: XPSourceType;
  sourceId?: string;
  reason: string;
  idempotencyKey?: string;
  createdAt: Date;
}
