// Habitat Telemetry Service Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/core/observability/telemetry_service.dart';

class MockTelemetryClient implements ITelemetryClient {
  final List<dynamic> errors = [];
  final List<TelemetryBreadcrumb> breadcrumbs = [];
  final Map<String, String> tags = {};

  @override
  Future<void> recordError(dynamic error, StackTrace? stackTrace,
      {String? reason, bool fatal = false}) async {
    errors.add({'error': error, 'reason': reason, 'fatal': fatal});
  }

  @override
  Future<void> recordBreadcrumb(TelemetryBreadcrumb breadcrumb) async {
    breadcrumbs.add(breadcrumb);
  }

  @override
  Future<void> recordDiagnosticEvent(DiagnosticEventType event,
      {Map<String, dynamic>? metadata}) async {}

  @override
  Future<void> setCustomTag(String key, String value) async {
    tags[key] = value;
  }
}

void main() {
  group('TelemetryService Tests', () {
    late MockTelemetryClient mockClient;
    late TelemetryService telemetry;

    setUp(() {
      mockClient = MockTelemetryClient();
      telemetry = TelemetryService.instance;
      telemetry.initialize(client: mockClient);
    });

    test('initializes and records breadcrumbs', () {
      expect(telemetry.isInitialized, isTrue);

      telemetry.recordBreadcrumb('alarm', 'Alarm scheduled for mission_001');
      expect(telemetry.breadcrumbs.length, equals(1));
      expect(telemetry.breadcrumbs.first.category, equals('alarm'));
      expect(telemetry.breadcrumbs.first.message,
          equals('Alarm scheduled for mission_001'));
      expect(mockClient.breadcrumbs.length, equals(1));
    });

    test('redacts email addresses and IP addresses from breadcrumb JSON', () {
      final crumb = TelemetryBreadcrumb(
        category: 'auth',
        message: 'User test.user@example.com connected from 192.168.1.1',
        timestamp: DateTime.now(),
      );

      final json = crumb.toJson();
      expect(json['message'], contains('[REDACTED_EMAIL]'));
      expect(json['message'], contains('[REDACTED_IP]'));
      expect(json['message'], isNot(contains('test.user@example.com')));
      expect(json['message'], isNot(contains('192.168.1.1')));
    });

    test('records errors through telemetry client', () {
      telemetry.recordError(
        Exception('Network timeout'),
        null,
        reason: 'Sync retry failure',
        fatal: false,
      );

      expect(mockClient.errors.length, equals(1));
      expect(mockClient.errors.first['reason'], equals('Sync retry failure'));
      expect(mockClient.errors.first['fatal'], isFalse);
    });
  });
}
