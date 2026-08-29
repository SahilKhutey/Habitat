// Habitat Health Master Service Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/health/domain/models/meal_entry.dart';
import 'package:habitat_mobile/features/health/domain/repositories/health_repository.dart';
import 'package:habitat_mobile/features/health/domain/services/health_service.dart';
import 'package:habitat_mobile/features/health/domain/services/meal_service.dart';
import 'package:habitat_mobile/features/health/domain/services/nap_service.dart';
import 'package:habitat_mobile/features/health/domain/services/water_service.dart';

void main() {
  late LocalDatabase db;
  late HealthRepository repo;
  late WaterService waterService;
  late MealService mealService;
  late NapService napService;
  late HealthService healthService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    repo = HealthRepository(db);
    waterService = WaterService(repo);
    mealService = MealService(repo);
    napService = NapService(repo);
    healthService = HealthService(
      waterService: waterService,
      mealService: mealService,
      napService: napService,
    );
  });

  group('HealthService Master Summary Tests', () {
    test('getTodaySummary() combines water, meals, and naps cleanly', () {
      waterService.addWater(500);
      waterService.addWater(250);
      mealService.logMeal(type: MealType.breakfast, notes: 'Eggs');
      mealService.logMeal(type: MealType.lunch, notes: 'Salad');
      napService.startNap();

      final summary = healthService.getTodaySummary();

      expect(summary.water.consumedMilliliters, equals(750));
      expect(summary.water.progressPercentage, equals(750 / 2000));
      expect(summary.meals.loggedCount, equals(2));
      expect(summary.meals.hasBreakfast, isTrue);
      expect(summary.meals.hasLunch, isTrue);
      expect(summary.meals.hasDinner, isFalse);
      expect(summary.nap.isRunning, isTrue);
      expect(summary.isDayActive, isTrue);
    });

    test('getMultiDayHistory(7) produces 7 historical day summaries', () {
      final history = healthService.getMultiDayHistory(7);
      expect(history.length, equals(7));
      expect(history.first.date.day, equals(DateTime.now().day));
    });
  });
}
