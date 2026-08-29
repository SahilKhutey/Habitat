// Habitat Meals Application Controller
import 'package:flutter/foundation.dart';
import '../../../database/local_database.dart';
import '../domain/models/meal_entry.dart';
import '../domain/services/meal_service.dart';

class MealController extends ChangeNotifier {
  final MealService _mealService;
  final LocalDatabase _database;

  late MealSummaryModel summary;

  MealController({
    required MealService mealService,
    required LocalDatabase database,
  })  : _mealService = mealService,
        _database = database {
    summary = _mealService.getTodaySummary();
    _database.changes.addListener(_onDatabaseChanged);
  }

  void logMeal({
    required MealType type,
    String? notes,
    DateTime? timestamp,
  }) {
    _mealService.logMeal(
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
    _mealService.updateMeal(
      id: id,
      type: type,
      notes: notes,
    );
  }

  void deleteMeal(String id) {
    _mealService.deleteMeal(id);
  }

  void _onDatabaseChanged() {
    summary = _mealService.getTodaySummary();
    notifyListeners();
  }

  @override
  void dispose() {
    _database.changes.removeListener(_onDatabaseChanged);
    super.dispose();
  }
}
