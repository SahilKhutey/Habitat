// Habitat Real Progression & XP Ledger Application Controller
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../../database/local_database.dart';

class ProgressionController extends ChangeNotifier {
  final LocalDatabase _database;
  bool isLoading = false;

  ProgressionController({LocalDatabase? database})
      : _database = database ?? LocalDatabase.instance {
    _database.changes.addListener(_onDatabaseChanged);
  }

  /// Total XP derived strictly from the append-only XP event ledger
  int get xpBalance => _database.getTotalXP();

  /// Authoritative Level formula: floor(sqrt(totalXp / 100)) + 1
  int get level {
    if (xpBalance <= 0) return 1;
    return (sqrt(xpBalance / 100)).floor() + 1;
  }

  /// XP required to complete current level
  int get xpForCurrentLevel => (level - 1) * (level - 1) * 100;

  /// XP required to reach next level
  int get xpForNextLevel => level * level * 100;

  /// Progress towards next level (0.0 to 1.0)
  double get levelProgress {
    final currentLevelXp = xpBalance - xpForCurrentLevel;
    final neededXp = xpForNextLevel - xpForCurrentLevel;
    if (neededXp <= 0) return 0.0;
    return (currentLevelXp / neededXp).clamp(0.0, 1.0);
  }

  /// Current streak statistics
  LocalStreak get streak => _database.getStreak();

  /// Available grace tokens
  int get graceTokens => _database.getGraceTokens();

  /// Unlocked achievements
  Set<String> get unlockedAchievements => _database.getUnlockedAchievements();

  /// Use a grace token to protect a broken streak
  bool useGraceToken() {
    final success = _database.useGraceToken();
    if (success) {
      notifyListeners();
    }
    return success;
  }

  void _onDatabaseChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _database.changes.removeListener(_onDatabaseChanged);
    super.dispose();
  }
}
