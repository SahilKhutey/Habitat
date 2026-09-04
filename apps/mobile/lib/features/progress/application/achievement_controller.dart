// Habitat Achievement Application Controller
import 'package:flutter/foundation.dart';
import '../../../database/local_database.dart';
import '../domain/models/achievement_model.dart';
import '../domain/services/achievement_service.dart';

class AchievementController extends ChangeNotifier {
  final AchievementService _achievementService;
  final LocalDatabase _database;

  String activeFilter = 'ALL';
  late List<AchievementModel> allAchievements;

  AchievementController({
    required AchievementService achievementService,
    required LocalDatabase database,
  })  : _achievementService = achievementService,
        _database = database {
    allAchievements = _achievementService.getAllAchievements();
    _database.changes.addListener(_onDataChanged);
  }

  List<AchievementModel> get filteredAchievements {
    return switch (activeFilter.toUpperCase()) {
      'UNLOCKED' => allAchievements.where((a) => a.isUnlocked).toList(),
      'LOCKED' => allAchievements.where((a) => !a.isUnlocked).toList(),
      'TASKS' => allAchievements
          .where((a) => a.category == AchievementCategory.tasks)
          .toList(),
      'STREAKS' => allAchievements
          .where((a) => a.category == AchievementCategory.streaks)
          .toList(),
      'HEALTH' => allAchievements
          .where((a) => a.category == AchievementCategory.health)
          .toList(),
      _ => allAchievements,
    };
  }

  void setFilter(String filter) {
    activeFilter = filter;
    notifyListeners();
  }

  void _onDataChanged() {
    _achievementService.evaluateAndUnlock();
    allAchievements = _achievementService.getAllAchievements();
    notifyListeners();
  }

  @override
  void dispose() {
    _database.changes.removeListener(_onDataChanged);
    super.dispose();
  }
}
