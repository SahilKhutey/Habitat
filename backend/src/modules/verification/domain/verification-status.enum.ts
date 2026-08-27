// Verification Lifecycle Status & Decision Enums

export enum VerificationStatus {
  QUEUED = 'QUEUED',
  PROCESSING = 'PROCESSING',
  ANALYZING = 'ANALYZING',
  DECIDING = 'DECIDING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
  MANUAL_REVIEW = 'MANUAL_REVIEW',
  EXPIRED = 'EXPIRED'
}

export enum VerificationDecision {
  ACCEPT = 'ACCEPT',
  REJECT = 'REJECT',
  REVIEW = 'REVIEW'
}
