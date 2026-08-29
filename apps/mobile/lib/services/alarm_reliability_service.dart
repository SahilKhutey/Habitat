// Flutter Mobile Alarm Reliability Diagnostic & Test Engine
import 'dart:async';
import 'dart:io';
import '../features/alarms/domain/alarm_health_models.dart';

class AlarmReliabilityService {
  static final AlarmReliabilityService instance = AlarmReliabilityService._internal();
  AlarmReliabilityService._internal();

  /// Evaluates device reliability based on platform, exact alarm permission, and manufacturer
  AlarmHealth diagnose({
    bool canScheduleExact = true,
    bool notificationsEnabled = true,
    bool isBatteryOptimizationIgnored = false,
    bool isBackgroundRestricted = false,
    String? manufacturerOverride,
  }) {
    final isIos = Platform.isIOS;
    final manufacturer = manufacturerOverride ?? (isIos ? 'Apple' : 'Android');
    final oem = _resolveOEM(manufacturer);
    final oemGuidance = _getGuidance(oem);

    final exactStatus = isIos
        ? DiagnosticStatus.confirmed
        : (canScheduleExact ? DiagnosticStatus.confirmed : DiagnosticStatus.actionRecommended);

    final notifStatus = notificationsEnabled ? DiagnosticStatus.confirmed : DiagnosticStatus.actionRecommended;

    final batteryStatus = isIos
        ? DiagnosticStatus.confirmed
        : (isBatteryOptimizationIgnored ? DiagnosticStatus.confirmed : DiagnosticStatus.actionRecommended);

    final bgStatus = isBackgroundRestricted ? DiagnosticStatus.actionRecommended : DiagnosticStatus.confirmed;

    ReliabilityTier tier = ReliabilityTier.excellent;
    if (exactStatus == DiagnosticStatus.actionRecommended || notifStatus == DiagnosticStatus.actionRecommended) {
      tier = ReliabilityTier.critical;
    } else if (batteryStatus == DiagnosticStatus.actionRecommended || bgStatus == DiagnosticStatus.actionRecommended) {
      tier = oemGuidance.riskLevel == 'HIGH' ? ReliabilityTier.needsAttention : ReliabilityTier.good;
    }

    return AlarmHealth(
      canScheduleExactAlarms: exactStatus,
      notificationsEnabled: notifStatus,
      batteryOptimizationStatus: batteryStatus,
      backgroundExecution: bgStatus,
      platform: isIos ? 'ios' : 'android',
      osVersion: Platform.operatingSystemVersion,
      manufacturer: manufacturer,
      overallReliability: tier,
      oemGuidance: oemGuidance,
    );
  }

  OEMVendor _resolveOEM(String manufacturer) {
    final m = manufacturer.toLowerCase();
    if (m.contains('samsung')) return OEMVendor.samsung;
    if (m.contains('xiaomi') || m.contains('redmi') || m.contains('poco')) return OEMVendor.xiaomi;
    if (m.contains('oneplus')) return OEMVendor.oneplus;
    if (m.contains('oppo')) return OEMVendor.oppo;
    if (m.contains('vivo') || m.contains('iqoo')) return OEMVendor.vivo;
    if (m.contains('realme')) return OEMVendor.realme;
    if (m.contains('google') || m.contains('pixel') || m.contains('motorola')) return OEMVendor.pixel;
    return OEMVendor.other;
  }

  OEMGuidance _getGuidance(OEMVendor oem) {
    switch (oem) {
      case OEMVendor.samsung:
        return const OEMGuidance(
          oemName: OEMVendor.samsung,
          riskLevel: 'HIGH',
          specificSteps: [
            'Go to Settings > Battery and Device Care > Battery > Background Usage Limits.',
            'Add Habitat to "Never Sleeping Apps".',
          ],
          settingsIntentAction: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        );
      case OEMVendor.xiaomi:
        return const OEMGuidance(
          oemName: OEMVendor.xiaomi,
          riskLevel: 'HIGH',
          specificSteps: [
            'Go to Settings > Apps > Manage Apps > Habitat.',
            'Enable "Autostart".',
            'Under "Battery Saver", select "No Restrictions".',
          ],
          settingsIntentAction: 'miui.intent.action.OP_AUTO_START',
        );
      case OEMVendor.oneplus:
        return const OEMGuidance(
          oemName: OEMVendor.oneplus,
          riskLevel: 'HIGH',
          specificSteps: [
            'Go to Settings > Battery > Battery Optimization > Habitat.',
            'Select "Don\'t Optimize".',
          ],
          settingsIntentAction: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        );
      default:
        return const OEMGuidance(
          oemName: OEMVendor.pixel,
          riskLevel: 'LOW',
          specificSteps: [
            'Go to Settings > Apps > Habitat > Battery.',
            'Select "Unrestricted".',
          ],
        );
    }
  }
}
