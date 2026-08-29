// Flutter Mobile Alarm Health & Diagnostic Domain Models

enum DiagnosticStatus { confirmed, actionRecommended, cannotVerify }

enum OEMVendor { samsung, xiaomi, oneplus, oppo, vivo, realme, pixel, other }

enum ReliabilityTier { excellent, good, needsAttention, critical }

class OEMGuidance {
  final OEMVendor oemName;
  final String riskLevel;
  final List<String> specificSteps;
  final String? settingsIntentAction;

  const OEMGuidance({
    required this.oemName,
    required this.riskLevel,
    required this.specificSteps,
    this.settingsIntentAction,
  });

  Map<String, dynamic> toJson() => {
        'oemName': oemName.name,
        'riskLevel': riskLevel,
        'specificSteps': specificSteps,
        'settingsIntentAction': settingsIntentAction,
      };
}

class AlarmHealth {
  final DiagnosticStatus canScheduleExactAlarms;
  final DiagnosticStatus notificationsEnabled;
  final DiagnosticStatus batteryOptimizationStatus;
  final DiagnosticStatus backgroundExecution;
  final String platform;
  final String osVersion;
  final String manufacturer;
  final ReliabilityTier overallReliability;
  final OEMGuidance? oemGuidance;

  const AlarmHealth({
    required this.canScheduleExactAlarms,
    required this.notificationsEnabled,
    required this.batteryOptimizationStatus,
    required this.backgroundExecution,
    required this.platform,
    required this.osVersion,
    required this.manufacturer,
    required this.overallReliability,
    this.oemGuidance,
  });
}
