// Habitat Nap Service Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/health/domain/repositories/health_repository.dart';
import 'package:habitat_mobile/features/health/domain/services/nap_service.dart';

void main() {
  late LocalDatabase db;
  late NapService napService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    napService = NapService(HealthRepository(db));
  });

  group('NapService Unit Tests', () {
    test('startNap() creates a running session and getCurrentNap() returns it', () {
      final session = napService.startNap();
      expect(session.isRunning, isTrue);

      final current = napService.getCurrentNap();
      expect(current, isNotNull);
      expect(current!.id, equals(session.id));
      expect(current.isRunning, isTrue);

      final summary = napService.getTodaySummary();
      expect(summary.isRunning, isTrue);
    });

    test('stopNap() finalizes session with duration', () {
      final startTime = DateTime.now().subtract(const Duration(minutes: 35));
      napService.startNap(startedAt: startTime);

      napService.stopNap(endedAt: DateTime.now());

      final current = napService.getCurrentNap();
      expect(current, isNull);

      final summary = napService.getTodaySummary();
      expect(summary.isRunning, isFalse);
      expect(summary.totalMinutes, greaterThanOrEqualTo(34));
      expect(summary.todayNaps.length, equals(1));
      expect(summary.formattedDuration, contains('35 min'));
    });
  });
}
