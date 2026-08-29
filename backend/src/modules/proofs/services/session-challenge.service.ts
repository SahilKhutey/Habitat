// Cryptographic Proof Session Challenge & Nonce Service
import { randomBytes, createHash } from 'crypto';
import { v4 as uuidv4 } from 'uuid';

export interface ProofSessionChallenge {
  sessionId: string;
  sessionNonce: string;
  missionId: string;
  userId: string;
  challengeType: 'PUSHUP_CADENCE' | 'STEADY_HOLD' | 'CONTINUOUS_MOTION';
  promptInstruction: string;
  issuedAt: string;
  expiresAt: string;
  isConsumed: boolean;
}

export class SessionChallengeService {
  private static challenges: Map<string, ProofSessionChallenge> = new Map();
  private static readonly TTL_MS = 5 * 60 * 1000; // 5 minutes

  /**
   * Generates a single-use, time-bound cryptographic session nonce and challenge
   */
  public static issueChallenge(missionId: string, userId: string): ProofSessionChallenge {
    const sessionId = uuidv4();
    const sessionNonce = randomBytes(32).toString('hex');
    const now = new Date();
    const expiresAt = new Date(now.getTime() + this.TTL_MS);

    // Deterministic cadence challenge based on nonce
    const promptInstruction = 'Perform designated push-ups with continuous camera visibility.';

    const challenge: ProofSessionChallenge = {
      sessionId,
      sessionNonce,
      missionId,
      userId,
      challengeType: 'PUSHUP_CADENCE',
      promptInstruction,
      issuedAt: now.toISOString(),
      expiresAt: expiresAt.toISOString(),
      isConsumed: false
    };

    this.challenges.set(sessionId, challenge);
    return challenge;
  }

  /**
   * Validates and single-use consumes the session nonce
   */
  public static validateAndConsumeNonce(
    sessionId: string,
    sessionNonce: string
  ): { isValid: boolean; reason?: string; challenge?: ProofSessionChallenge } {
    const challenge = this.challenges.get(sessionId);

    if (!challenge) {
      return { isValid: false, reason: 'Invalid or expired proof session ID.' };
    }

    if (challenge.isConsumed) {
      return { isValid: false, reason: 'Proof session nonce has already been consumed (replay blocked).' };
    }

    const now = new Date();
    if (now > new Date(challenge.expiresAt)) {
      this.challenges.delete(sessionId);
      return { isValid: false, reason: 'Proof session has expired. Request a new session challenge.' };
    }

    if (challenge.sessionNonce !== sessionNonce) {
      return { isValid: false, reason: 'Cryptographic session nonce mismatch.' };
    }

    // Mark single-use consumed
    challenge.isConsumed = true;
    this.challenges.set(sessionId, challenge);

    return { isValid: true, challenge };
  }

  /**
   * Verifies SHA-256 payload integrity hash
   */
  public static verifyPayloadHash(payload: unknown, expectedHash: string): boolean {
    const json = typeof payload === 'string' ? payload : JSON.stringify(payload);
    const computed = createHash('sha256').update(json).digest('hex');
    return computed === expectedHash;
  }

  /**
   * Cleans expired challenges
   */
  public static cleanExpired(): void {
    const now = new Date();
    for (const [id, challenge] of this.challenges.entries()) {
      if (now > new Date(challenge.expiresAt)) {
        this.challenges.delete(id);
      }
    }
  }

  /**
   * Reset helper for testing
   */
  public static resetForTesting(): void {
    this.challenges.clear();
  }
}
