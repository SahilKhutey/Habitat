// Automated Flutter Test Suite for Alarm Reliability & Exact Alarm Capabilities (Milestone C2/C3)
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/features/alarms/domain/alarm_health_models.dart';
import 'package:habitat_mobile/services/alarm_reliability_service.dart';

void main() {
  group('Milestone C2 / C3: Alarm Reliability & Exact Alarm Capabilities', () {
    final service = AlarmReliabilityService.instance;

    test('C2.1: Diagnoses Pixel devices with standard unrestricted battery profile', () {
      final health = service.diagnose(
        canScheduleExact: true,
        notificationsEnabled: true,
        isBatteryOptimizationIgnored: true,
        manufacturerOverride: 'Google',
      );

      expect(health.canScheduleExactAlarms, DiagnosticStatus.confirmed);
      expect(health.batteryOptimizationStatus, DiagnosticStatus.confirmed);
      expect(health.overallReliability, ReliabilityTier.excellent);
      expect(health.oemGuidance?.oemName, OEMVendor.pixel);
    });

    test('C2.2: Generates critical alert and high-risk guidance for Samsung One UI', () {
      final health = service.diagnose(
        canScheduleExact: true,
        notificationsEnabled: true,
        isBatteryOptimizationIgnored: false,
        manufacturerOverride: 'Samsung',
      );

      expect(health.batteryOptimizationStatus, DiagnosticStatus.actionRecommended);
      expect(health.overallReliability, ReliabilityTier.needsAttention);
      expect(health.oemGuidance?.oemName, OEMVendor.samsung);
      expect(health.oemGuidance?.specificSteps.any((s) => s.contains('Never Sleeping Apps')), true);
    });

    test('C2.3: Generates Autostart & No Restrictions guidance for Xiaomi HyperOS / MIUI', () {
      final health = service.diagnose(
        canScheduleExact: true,
        notificationsEnabled: true,
        isBatteryOptimizationIgnored: false,
        manufacturerOverride: 'Xiaomi',
      );

      expect(health.oemGuidance?.oemName, OEMVendor.xiaomi);
      expect(health.oemGuidance?.specificSteps.any((s) => s.contains('Autostart')), true);
      expect(health.oemGuidance?.specificSteps.any((s) => s.contains('No Restrictions')), true);
    });

    test('C3.1: Flags critical degradation warning when exact alarm capability is disabled', () {
      final health = service.diagnose(
        canScheduleExact: false,
        notificationsEnabled: true,
        isBatteryOptimizationIgnored: true,
        manufacturerOverride: 'Google',
      );

      expect(health.canScheduleExactAlarms, DiagnosticStatus.actionRecommended);
      expect(health.overallReliability, ReliabilityTier.critical);

      final warning = service.getDegradationWarning(health);
      expect(warning, contains('Exact alarm access is disabled'));
    });

    test('C2.4: Records Test My Alarm verification state idempotently', () {
      service.recordTestVerificationSuccess();
      final state = service.persistedState;

      expect(state, isNotNull);
      expect(state?.isVerifiedViaTest, true);
      expect(state?.lastTestResult, 'success');
      expect(state?.overallStatus, ReliabilityStatus.verified);
    });
  });
}
