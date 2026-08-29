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

  const HealthSummary({
    required this.waterMl,
    required this.waterTargetMl,
    required this.mealsLogged,
    required this.mealsTarget,
    required this.totalNapDuration,
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
  late List<WaterEntryModel> todayWater;
  late List<MealEntryModel> todayMeals;
  late List<NapEntryModel> todayNaps;

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
    final waterTotal = todayWater.fold<int>(0, (sum, i) => sum + i.amountMl);

    todayMeals = _mealService.getTodayMeals();
    final mealsCount = todayMeals.length;

    todayNaps = _napService.getTodayNaps();
    final totalNapMinutes = todayNaps.fold<int>(0, (sum, i) => sum + i.durationMinutes);

    summary = HealthSummary(
      waterMl: waterTotal,
      waterTargetMl: 2500,
      mealsLogged: mealsCount,
      mealsTarget: 4,
      totalNapDuration: Duration(minutes: totalNapMinutes),
    );
  }

  void addWater(int amountMl) {
    _waterService.logWater(amountMl: amountMl);
  }

  void addMeal({required MealSlot slot, required String name, required int calories}) {
    _mealService.logMeal(slot: slot, name: name, calories: calories);
  }

  void logNap({required int durationMinutes, required String quality}) {
    _napService.logNap(durationMinutes: durationMinutes, qualityRating: quality);
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
