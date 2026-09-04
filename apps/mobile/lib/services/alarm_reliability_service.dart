// Flutter Mobile Alarm Reliability Diagnostic, OEM Guidance & Empirical Test Engine (Milestone C2/C3)
import 'dart:async';
import 'dart:io';
import '../core/alarm/battery_optimization_service.dart';
import '../features/alarms/domain/alarm_health_models.dart';

enum ReliabilityStatus { ready, degraded, restricted, verified }

class PersistedReliabilityState {
  final bool batteryOptimizationChecked;
  final bool exactAlarmChecked;
  final bool isVerifiedViaTest;
  final String lastReliabilityCheck;
  final String? lastTestAlarm;
  final String lastTestResult;
  final ReliabilityStatus overallStatus;

  const PersistedReliabilityState({
    required this.batteryOptimizationChecked,
    required this.exactAlarmChecked,
    required this.isVerifiedViaTest,
    required this.lastReliabilityCheck,
    this.lastTestAlarm,
    required this.lastTestResult,
    required this.overallStatus,
  });

  Map<String, dynamic> toJson() => {
        'batteryOptimizationChecked': batteryOptimizationChecked,
        'exactAlarmChecked': exactAlarmChecked,
        'isVerifiedViaTest': isVerifiedViaTest,
        'lastReliabilityCheck': lastReliabilityCheck,
        'lastTestAlarm': lastTestAlarm,
        'lastTestResult': lastTestResult,
        'overallStatus': overallStatus.name,
      };
}

class AlarmReliabilityService {
  static final AlarmReliabilityService instance =
      AlarmReliabilityService._internal();
  AlarmReliabilityService._internal();

  IBatteryOptimizationService batteryService =
      BatteryOptimizationService.instance;
  PersistedReliabilityState? _persistedState;

  PersistedReliabilityState? get persistedState => _persistedState;

  /// Evaluates real-time device reliability using native capabilities
  Future<AlarmHealth> diagnoseAsync({
    bool notificationsEnabled = true,
    String? manufacturerOverride,
  }) async {
    final canScheduleExact = await batteryService.canScheduleExactAlarms();
    final isBatteryIgnored = await batteryService.isOptimizationIgnored();
    final manufacturer =
        manufacturerOverride ?? await batteryService.getDeviceManufacturer();

    return diagnose(
      canScheduleExact: canScheduleExact,
      notificationsEnabled: notificationsEnabled,
      isBatteryOptimizationIgnored: isBatteryIgnored,
      manufacturerOverride: manufacturer,
    );
  }

  /// Synchronous diagnostic calculation given capability states
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
        : (canScheduleExact
            ? DiagnosticStatus.confirmed
            : DiagnosticStatus.actionRecommended);

    final notifStatus = notificationsEnabled
        ? DiagnosticStatus.confirmed
        : DiagnosticStatus.actionRecommended;

    final batteryStatus = isIos
        ? DiagnosticStatus.confirmed
        : (isBatteryOptimizationIgnored
            ? DiagnosticStatus.confirmed
            : DiagnosticStatus.actionRecommended);

    final bgStatus = isBackgroundRestricted
        ? DiagnosticStatus.actionRecommended
        : DiagnosticStatus.confirmed;

    ReliabilityTier tier = ReliabilityTier.excellent;
    if (exactStatus == DiagnosticStatus.actionRecommended ||
        notifStatus == DiagnosticStatus.actionRecommended) {
      tier = ReliabilityTier.critical;
    } else if (batteryStatus == DiagnosticStatus.actionRecommended ||
        bgStatus == DiagnosticStatus.actionRecommended) {
      tier = oemGuidance.riskLevel == 'HIGH'
          ? ReliabilityTier.needsAttention
          : ReliabilityTier.good;
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

  /// Records successful empirical 15-second test alarm verification
  void recordTestVerificationSuccess() {
    final now = DateTime.now().toUtc().toIso8601String();
    _persistedState = PersistedReliabilityState(
      batteryOptimizationChecked: true,
      exactAlarmChecked: true,
      isVerifiedViaTest: true,
      lastReliabilityCheck: now,
      lastTestAlarm: now,
      lastTestResult: 'success',
      overallStatus: ReliabilityStatus.verified,
    );
  }

  /// Resolves user-facing degradation banner when exact alarms or battery optimizations are missing
  String? getDegradationWarning(AlarmHealth health) {
    if (health.canScheduleExactAlarms == DiagnosticStatus.actionRecommended) {
      return 'Exact alarm access is disabled. Android may deliver this alarm later than scheduled.';
    }
    if (health.batteryOptimizationStatus ==
        DiagnosticStatus.actionRecommended) {
      return 'Battery optimization is active. Your alarms may be delayed or silenced when the phone is locked.';
    }
    if (health.notificationsEnabled == DiagnosticStatus.actionRecommended) {
      return 'Notifications are disabled. Habitat cannot ring or show your wake-up mission.';
    }
    return null;
  }

  OEMVendor _resolveOEM(String manufacturer) {
    final m = manufacturer.toLowerCase();
    if (m.contains('samsung')) return OEMVendor.samsung;
    if (m.contains('xiaomi') || m.contains('redmi') || m.contains('poco'))
      return OEMVendor.xiaomi;
    if (m.contains('oneplus')) return OEMVendor.oneplus;
    if (m.contains('oppo')) return OEMVendor.oppo;
    if (m.contains('vivo') || m.contains('iqoo')) return OEMVendor.vivo;
    if (m.contains('realme')) return OEMVendor.realme;
    if (m.contains('huawei') || m.contains('honor')) return OEMVendor.other;
    if (m.contains('google') || m.contains('pixel') || m.contains('motorola'))
      return OEMVendor.pixel;
    return OEMVendor.other;
  }

  OEMGuidance _getGuidance(OEMVendor oem) {
    switch (oem) {
      case OEMVendor.samsung:
        return const OEMGuidance(
          oemName: OEMVendor.samsung,
          riskLevel: 'HIGH',
          specificSteps: [
            '1. Go to Settings > Apps > Special Access > "Appear on top" and enable Habitat.',
            '2. Go to Settings > Battery and Device Care > Battery > Background Usage Limits.',
            '3. Add Habitat to "Never Sleeping Apps" and set App Battery to "Unrestricted".',
          ],
          settingsIntentAction:
              'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        );
      case OEMVendor.xiaomi:
        return const OEMGuidance(
          oemName: OEMVendor.xiaomi,
          riskLevel: 'HIGH',
          specificSteps: [
            '1. Go to Settings > Apps > Manage Apps > Habitat.',
            '2. Enable the "Autostart" toggle.',
            '3. Under "Battery Saver", select "No Restrictions".',
            '4. In Other Permissions, enable "Show on Lock screen".',
          ],
          settingsIntentAction: 'miui.intent.action.OP_AUTO_START',
        );
      case OEMVendor.oneplus:
        return const OEMGuidance(
          oemName: OEMVendor.oneplus,
          riskLevel: 'HIGH',
          specificSteps: [
            '1. Go to Settings > Battery > Battery Optimization > Habitat.',
            '2. Select "Don\'t Optimize".',
            '3. Allow background execution in App Info.',
          ],
          settingsIntentAction:
              'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        );
      default:
        return const OEMGuidance(
          oemName: OEMVendor.pixel,
          riskLevel: 'LOW',
          specificSteps: [
            '1. Go to Settings > Apps > Habitat > Alarms & reminders > Allow setting alarms.',
            '2. Go to App Battery Usage > Select "Unrestricted".',
          ],
        );
    }
  }
}
