// Habitat Proof Heuristics & Anti-Cheat Validation Rules
import { ProofAsset, Task } from './types';

export interface VerificationResult {
  isValid: boolean;
  confidenceScore: number;
  rejectionReason?: string;
}

export class AntiCheatValidator {
  /**
   * Validates photo or video proof against task rules and anti-cheat constraints
   */
  public static validateProof(
    proof: Partial<ProofAsset>,
    task: Task,
    submissionTime: Date = new Date()
  ): VerificationResult {
    // 1. Timestamp Freshness Check (Must be captured within last 3 minutes of submission)
    if (proof.capturedAt) {
      const capturedTime = new Date(proof.capturedAt).getTime();
      const now = submissionTime.getTime();
      const ageInSeconds = Math.abs(now - capturedTime) / 1000;

      if (ageInSeconds > 180) {
        return {
          isValid: false,
          confidenceScore: 0.1,
          rejectionReason: 'Proof timestamp indicates media was captured too long ago. Fresh capture required.'
        };
      }
    }

    // 2. Minimum Scene Illumination (Prevents snapping a dark photo under the blanket)
    if (task.validationRules.minLuminance && proof.deviceMetadata?.ambientLux !== undefined) {
      if (proof.deviceMetadata.ambientLux < task.validationRules.minLuminance) {
        return {
          isValid: false,
          confidenceScore: 0.2,
          rejectionReason: `Scene is too dark (${proof.deviceMetadata.ambientLux} lux). Turn on lights or step into morning sunlight.`
        };
      }
    }

    // 3. Motion Validation for Exercise & Physical tasks
    if (task.category === 'exercise' && proof.deviceMetadata?.accelerometerMotion === false) {
      return {
        isValid: false,
        confidenceScore: 0.3,
        rejectionReason: 'No physical device motion detected during exercise task capture.'
      };
    }

    // Baseline Heuristic Verification Passed
    return {
      isValid: true,
      confidenceScore: 0.95
    };
  }
}
