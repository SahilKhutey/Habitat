// Habitat Water Intake Application Controller
import 'package:flutter/foundation.dart';
import '../../../database/local_database.dart';
import '../domain/models/water_entry.dart';
import '../domain/services/water_service.dart';

class WaterController extends ChangeNotifier {
  final WaterService _waterService;
  final LocalDatabase _database;

  late WaterSummaryModel summary;

  WaterController({
    required WaterService waterService,
    required LocalDatabase database,
  })  : _waterService = waterService,
        _database = database {
    summary = _waterService.getTodaySummary();
    _database.changes.addListener(_onDatabaseChanged);
  }

  void addPreset(int milliliters) {
    _waterService.addWater(milliliters);
  }

  void addCustom(int milliliters) {
    if (milliliters > 0) {
      _waterService.addWater(milliliters);
    }
  }

  void removeEntry(String id) {
    _waterService.removeWater(id);
  }

  void setGoal(int milliliters) {
    _waterService.setGoal(milliliters);
  }

  void _onDatabaseChanged() {
    summary = _waterService.getTodaySummary();
    notifyListeners();
  }

  @override
  void dispose() {
    _database.changes.removeListener(_onDatabaseChanged);
    super.dispose();
  }
}
