/// Shared constants and configuration for Habitat Discipline Platform
library shared_config;

class AppConstants {
  static const String appName = 'Discipline';
  static const String appVersion = '0.1.0';
  static const String defaultApiBaseUrl = 'http://localhost:4000/api/v1';

  // Mission Engine Thresholds
  static const int instantActionThresholdSec = 120; // 2 minutes
  static const double speedMultiplier = 1.5; // +50% XP
  static const int standardRetryIntervalMin = 5;
  static const int hardcoreRetryIntervalMin = 3;
}
