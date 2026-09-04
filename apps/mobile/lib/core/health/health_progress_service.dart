// Habitat Health & Progress Unified Data Service (Phase 16)
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../database/local_database.dart';

@immutable
class HealthProgressSummary {
  final double waterLiters;
  final int mealCount;
  final int napMinutes;
  final int totalXP;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> dailyCompletions;
  final Map<String, double> dailyWater;

  const HealthProgressSummary({
    required this.waterLiters,
    required this.mealCount,
    required this.napMinutes,
    required this.totalXP,
    required this.currentStreak,
    required this.longestStreak,
    required this.dailyCompletions,
    required this.dailyWater,
  });
}

class HealthProgressService {
  final LocalDatabase _database;

  HealthProgressService({LocalDatabase? database})
      : _database = database ?? LocalDatabase.instance;

  void addWaterMl(int ml) {
    _database.recordHealthLog(LocalHealthLog(
      id: 'health_${const Uuid().v4()}',
      type: 'WATER',
      recordedAt: DateTime.now(),
      amount: ml.toDouble(),
      unit: 'ml',
    ));
    _database.addWater(milliliters: ml);
  }

  void logMeal(String mealType, {String note = ''}) {
    _database.recordHealthLog(LocalHealthLog(
      id: 'health_${const Uuid().v4()}',
      type: 'MEAL',
      recordedAt: DateTime.now(),
      amount: 1,
      unit: 'meal',
      mealType: mealType.toUpperCase(),
      note: note,
    ));
    _database.addMeal(type: mealType.toLowerCase(), notes: note);
  }

  void logNap(Duration duration, {String note = ''}) {
    _database.recordHealthLog(LocalHealthLog(
      id: 'health_${const Uuid().v4()}',
      type: 'NAP',
      recordedAt: DateTime.now(),
      amount: duration.inMinutes.toDouble(),
      unit: 'minutes',
      durationMinutes: duration.inMinutes,
      note: note,
    ));
    _database.startNap();
    _database.stopNap(endedAt: DateTime.now().add(duration));
  }

  double get todayWaterLiters => _database.getTodayWaterLiters();
  int get todayMealCount => _database.getTodayMealCount();
  int get todayNapMinutes => _database.getTodayNapMinutes();
  int get totalXP => _database.getTotalXP();
  LocalStreak get streak => _database.getStreak();
  Map<String, int> get dailyCompletions => _database.getDailyCompletions();
  Map<String, double> get dailyWater => _database.getDailyWater();

  HealthProgressSummary getTodaySummary() {
    final streak = _database.getStreak();
    return HealthProgressSummary(
      waterLiters: _database.getTodayWaterLiters(),
      mealCount: _database.getTodayMealCount(),
      napMinutes: _database.getTodayNapMinutes(),
      totalXP: _database.getTotalXP(),
      currentStreak: streak.currentStreak,
      longestStreak: streak.longestStreak,
      dailyCompletions: _database.getDailyCompletions(),
      dailyWater: _database.getDailyWater(),
    );
  }
}
