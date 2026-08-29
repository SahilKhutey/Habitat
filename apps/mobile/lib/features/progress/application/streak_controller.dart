// Habitat Streak Application Controller
import 'package:flutter/foundation.dart';
import '../../../database/local_database.dart';
import '../domain/models/streak_model.dart';
import '../domain/services/streak_service.dart';

class StreakController extends ChangeNotifier {
  final StreakService _streakService;
  final LocalDatabase _database;

  late StreakModel streak;

  StreakController({
    required StreakService streakService,
    required LocalDatabase database,
  })  : _streakService = streakService,
        _database = database {
    streak = _streakService.getStreak();
    _database.changes.addListener(_onDataChanged);
  }

  bool useGraceToken() {
    final success = _streakService.useGraceToken();
    if (success) {
      streak = _streakService.getStreak();
      notifyListeners();
    }
    return success;
  }

  void _onDataChanged() {
    streak = _streakService.getStreak();
    notifyListeners();
  }

  @override
  void dispose() {
    _database.changes.removeListener(_onDataChanged);
    super.dispose();
  }
}
