// Feature Flags Service
import { FlagRepository } from './flag.repository';
import { FeatureFlagKey } from './flag.types';

export class FlagService {
  public static isEnabled(key: FeatureFlagKey, userId?: string): boolean {
    const flag = FlagRepository.getFlag(key);
    if (!flag) {
      // Default to enabled for development/core features
      return true;
    }
    if (!flag.enabled) return false;
    if (flag.rolloutPercentage >= 100) return true;

    // Deterministic hash-based rollout if userId provided
    if (userId) {
      let hash = 0;
      for (let i = 0; i < userId.length; i++) {
        hash = (hash << 5) - hash + userId.charCodeAt(i);
        hash |= 0;
      }
      const score = Math.abs(hash) % 100;
      return score < flag.rolloutPercentage;
    }

    return true;
  }
}
