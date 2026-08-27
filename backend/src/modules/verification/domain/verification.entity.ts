// Verification Domain Entity
import { VerificationStatus, VerificationDecision } from './verification-status.enum';
import { VerificationCheck, VerificationReason } from './verification-reason.enum';

export interface VerificationEntity {
  id: string;
  proofId: string;
  missionId: string;
  attemptId?: string;
  userId: string;
  status: VerificationStatus;
  decision?: VerificationDecision;
  confidence?: number;
  verifier: string;
  verifierVersion: string;
  reasons: VerificationReason[];
  checks: VerificationCheck[];
  startedAt?: Date;
  completedAt?: Date;
  createdAt: Date;
}
