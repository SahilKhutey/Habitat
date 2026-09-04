// Habitat Meal Service Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/health/domain/models/meal_entry.dart';
import 'package:habitat_mobile/features/health/domain/repositories/health_repository.dart';
import 'package:habitat_mobile/features/health/domain/services/meal_service.dart';

void main() {
  late LocalDatabase db;
  late MealService mealService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    mealService = MealService(HealthRepository(db));
  });

  group('MealService Unit Tests', () {
    test('logMeal() logs meal slots and evaluates flags', () {
      mealService.logMeal(type: MealType.breakfast, notes: 'Oatmeal');
      mealService.logMeal(type: MealType.dinner, notes: 'Salmon & Greens');

      final summary = mealService.getTodaySummary();
      expect(summary.loggedCount, equals(2));
      expect(summary.hasBreakfast, isTrue);
      expect(summary.hasDinner, isTrue);
      expect(summary.hasLunch, isFalse);
      expect(summary.hasSnack, isFalse);
      expect(summary.breakfastEntry?.notes, equals('Oatmeal'));
    });

    test('updateMeal() and deleteMeal() update state correctly', () {
      mealService.logMeal(type: MealType.lunch, notes: 'Soup');
      var summary = mealService.getTodaySummary();
      final mealId = summary.entries.first.id;

      mealService.updateMeal(
          id: mealId, type: MealType.lunch, notes: 'Soup & Rice');
      summary = mealService.getTodaySummary();
      expect(summary.lunchEntry?.notes, equals('Soup & Rice'));

      mealService.deleteMeal(mealId);
      summary = mealService.getTodaySummary();
      expect(summary.loggedCount, equals(0));
      expect(summary.hasLunch, isFalse);
    });
  });
}
