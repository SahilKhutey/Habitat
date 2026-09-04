// Habitat Master Health Application Controller & Summary
import 'package:flutter/foundation.dart';
import '../../../../database/local_database.dart';
import '../domain/models/meal_entry.dart';
import '../domain/models/nap_entry.dart';
import '../domain/models/water_entry.dart';
import '../domain/services/meal_service.dart';
import '../domain/services/nap_service.dart';
import '../domain/services/water_service.dart';

@immutable
class HealthSummary {
  final int waterMl;
  final int waterTargetMl;
  final int mealsLogged;
  final int mealsTarget;
  final Duration totalNapDuration;
  final WaterSummaryModel water;
  final MealSummaryModel meals;
  final NapSummaryModel nap;

  const HealthSummary({
    required this.waterMl,
    required this.waterTargetMl,
    required this.mealsLogged,
    required this.mealsTarget,
    required this.totalNapDuration,
    required this.water,
    required this.meals,
    required this.nap,
  });

  double get waterRatio =>
      waterTargetMl <= 0 ? 0.0 : (waterMl / waterTargetMl).clamp(0.0, 1.0);

  double get mealRatio =>
      mealsTarget <= 0 ? 0.0 : (mealsLogged / mealsTarget).clamp(0.0, 1.0);
}

class HealthController extends ChangeNotifier {
  final WaterService _waterService;
  final MealService _mealService;
  final NapService _napService;
  final LocalDatabase _database;

  late HealthSummary summary;
  List<WaterEntryModel> todayWater = [];
  List<MealEntryModel> todayMeals = [];
  List<NapEntryModel> todayNaps = [];

  HealthController({
    required WaterService waterService,
    required MealService mealService,
    required NapService napService,
    required LocalDatabase database,
  })  : _waterService = waterService,
        _mealService = mealService,
        _napService = napService,
        _database = database {
    _loadState();
    _database.changes.addListener(_onDataChanged);
  }

  void _loadState() {
    todayWater = _waterService.getTodayEntries();
    final waterTotal = todayWater.fold<int>(0, (sum, i) => sum + i.milliliters);

    final mealSummary = _mealService.getTodaySummary();
    todayMeals = mealSummary.entries;
    final mealsCount = todayMeals.length;

    final napSummary = _napService.getTodaySummary();
    todayNaps = napSummary.todayNaps;
    final totalNapMinutes =
        todayNaps.fold<int>(0, (sum, i) => sum + i.durationMinutes);

    summary = HealthSummary(
      waterMl: waterTotal,
      waterTargetMl: 2500,
      mealsLogged: mealsCount,
      mealsTarget: 4,
      totalNapDuration: Duration(minutes: totalNapMinutes),
      water: _waterService.getTodaySummary(),
      meals: mealSummary,
      nap: napSummary,
    );
  }

  void addWater(int amountMl) {
    _waterService.addWater(amountMl);
  }

  void addMeal(
      {MealType type = MealType.snack, String? name, int calories = 400}) {
    _mealService.logMeal(type: type, notes: name);
  }

  void logNap({required int durationMinutes, String? quality}) {
    _napService.startNap();
    _napService.stopNap();
  }

  void _onDataChanged() {
    _loadState();
    notifyListeners();
  }

  @override
  void dispose() {
    _database.changes.removeListener(_onDataChanged);
    super.dispose();
  }
}
