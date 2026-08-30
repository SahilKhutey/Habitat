// Habitat Water Service
import '../models/water_entry.dart';
import '../repositories/health_repository.dart';

class WaterService {
  final HealthRepository _repository;

  WaterService(this._repository);

  int getGoal() => _repository.getWaterGoal();

  void setGoal(int milliliters) => _repository.setWaterGoal(milliliters);

  void addWater(int milliliters, {DateTime? timestamp}) {
    _repository.addWater(milliliters, timestamp: timestamp);
  }

  void logWater({required int amountMl, DateTime? timestamp}) {
    addWater(amountMl, timestamp: timestamp);
  }

  List<WaterEntryModel> getTodayEntries([DateTime? date]) {
    return _repository.getWaterEntries(date ?? DateTime.now());
  }

  void removeWater(String id) {
    _repository.removeWater(id);
  }

  WaterSummaryModel getTodaySummary([DateTime? date]) {
    final day = date ?? DateTime.now();
    final entries = _repository.getWaterEntries(day);
    final consumed = entries.fold(0, (total, e) => total + e.milliliters);
    final target = _repository.getWaterGoal();

    return WaterSummaryModel(
      consumedMilliliters: consumed,
      targetMilliliters: target,
      entries: entries,
    );
  }

  List<WaterSummaryModel> getHistory([int days = 7]) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final date = now.subtract(Duration(days: i));
      return getTodaySummary(date);
    });
  }
}
