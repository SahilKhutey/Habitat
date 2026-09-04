// Habitat Health Repository Layer
import '../../../../database/local_database.dart';
import '../models/meal_entry.dart';
import '../models/nap_entry.dart';
import '../models/water_entry.dart';

class HealthRepository {
  final LocalDatabase _database;

  HealthRepository(this._database);

  // --- Water Operations ---
  int getWaterGoal() => _database.getWaterGoal();

  void setWaterGoal(int milliliters) => _database.setWaterGoal(milliliters);

  void addWater(int milliliters, {DateTime? timestamp}) {
    _database.addWater(milliliters: milliliters, recordedAt: timestamp);
  }

  void removeWater(String id) {
    _database.removeWaterEntry(id);
  }

  List<WaterEntryModel> getWaterEntries(DateTime day) {
    return _database
        .getWaterEntriesForDay(day)
        .map((e) => WaterEntryModel(
              id: e.id,
              milliliters: e.milliliters,
              timestamp: e.recordedAt,
            ))
        .toList();
  }

  // --- Meal Operations ---
  void addMeal({required MealType type, String? notes, DateTime? timestamp}) {
    _database.addMeal(
      type: type.name,
      notes: notes,
      recordedAt: timestamp,
    );
  }

  void updateMeal(
      {required String id,
      required MealType type,
      String? notes,
      DateTime? timestamp}) {
    _database.updateMealEntry(LocalMealEntry(
      id: id,
      type: type.name,
      notes: notes,
      recordedAt: timestamp ?? DateTime.now(),
    ));
  }

  void deleteMeal(String id) {
    _database.deleteMealEntry(id);
  }

  List<MealEntryModel> getMealEntries(DateTime day) {
    return _database
        .getMealEntriesForDay(day)
        .map((e) => MealEntryModel(
              id: e.id,
              type: _parseMealType(e.type),
              recordedAt: e.recordedAt,
              notes: e.notes,
              status: MealStatus.logged,
            ))
        .toList();
  }

  // --- Nap Operations ---
  NapEntryModel startNap({DateTime? startedAt}) {
    final entry = _database.startNap(startedAt: startedAt);
    return _mapNap(entry);
  }

  void stopNap({DateTime? endedAt}) {
    _database.stopNap(endedAt: endedAt);
  }

  List<NapEntryModel> getNapEntries(DateTime day) {
    return _database.getNapEntriesForDay(day).map(_mapNap).toList();
  }

  // --- Helpers ---
  NapEntryModel _mapNap(LocalNapEntry e) {
    return NapEntryModel(
      id: e.id,
      startedAt: e.startedAt,
      endedAt: e.endedAt,
      durationMinutes: e.durationMinutes,
      isRunning: e.isRunning,
    );
  }

  MealType _parseMealType(String raw) => switch (raw.toLowerCase()) {
        'breakfast' => MealType.breakfast,
        'lunch' => MealType.lunch,
        'snack' || 'snacks' => MealType.snack,
        'dinner' => MealType.dinner,
        _ => MealType.breakfast,
      };
}
