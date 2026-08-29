// Feature Flags Types
export type FeatureFlagKey =
  | 'SMART_COACH'
  | 'SOCIAL'
  | 'LEADERBOARDS'
  | 'GROUP_CHALLENGES'
  | 'PREMIUM_ANALYTICS'
  | 'OFFLINE_SYNC_V2'
  | 'INTELLIGENCE_ENABLED';

export interface FeatureFlagEntity {
  key: FeatureFlagKey;
  enabled: boolean;
  rolloutPercentage: number;
  description?: string;
}
