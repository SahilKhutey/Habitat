// Habitat Water Service Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/health/domain/repositories/health_repository.dart';
import 'package:habitat_mobile/features/health/domain/services/water_service.dart';

void main() {
  late LocalDatabase db;
  late WaterService waterService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    waterService = WaterService(HealthRepository(db));
  });

  group('WaterService Unit Tests', () {
    test('addWater() increments volume and stores entries', () {
      waterService.addWater(250);
      waterService.addWater(500);

      final summary = waterService.getTodaySummary();
      expect(summary.consumedMilliliters, equals(750));
      expect(summary.entries.length, equals(2));
      expect(summary.remainingMilliliters, equals(1250));
    });

    test('removeWater() removes entry and recalculates total', () {
      waterService.addWater(500);
      waterService.addWater(250);

      var summary = waterService.getTodaySummary();
      expect(summary.consumedMilliliters, equals(750));

      final firstEntryId = summary.entries.first.id;
      waterService.removeWater(firstEntryId);

      summary = waterService.getTodaySummary();
      expect(summary.consumedMilliliters, equals(250));
      expect(summary.entries.length, equals(1));
    });

    test('setGoal() adjusts target goal dynamically', () {
      waterService.setGoal(2500);
      expect(waterService.getGoal(), equals(2500));

      final summary = waterService.getTodaySummary();
      expect(summary.targetMilliliters, equals(2500));
    });
  });
}
