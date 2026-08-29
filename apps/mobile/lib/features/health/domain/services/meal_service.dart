// Habitat Meal Service
import '../models/meal_entry.dart';
import '../repositories/health_repository.dart';

class MealService {
  final HealthRepository _repository;

  MealService(this._repository);

  void logMeal({
    required MealType type,
    String? notes,
    DateTime? timestamp,
  }) {
    _repository.addMeal(
      type: type,
      notes: notes,
      timestamp: timestamp,
    );
  }

  void updateMeal({
    required String id,
    required MealType type,
    String? notes,
  }) {
    _repository.updateMeal(
      id: id,
      type: type,
      notes: notes,
    );
  }

  void deleteMeal(String id) {
    _repository.deleteMeal(id);
  }

  MealSummaryModel getTodaySummary([DateTime? date]) {
    final day = date ?? DateTime.now();
    final entries = _repository.getMealEntries(day);

    return MealSummaryModel(
      loggedCount: entries.length,
      targetCount: 4,
      entries: entries,
    );
  }

  List<MealSummaryModel> getHistory([int days = 7]) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final date = now.subtract(Duration(days: i));
      return getTodaySummary(date);
    });
  }
}
