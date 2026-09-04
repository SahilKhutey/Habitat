// Habitat Progress Repository Layer
import '../../../../database/local_database.dart';

class ProgressRepository {
  final LocalDatabase _database;

  ProgressRepository(this._database);

  List<LocalTask> getAllTasks() => _database.getAllTasks();

  List<LocalTaskAttempt> getAllAttempts() => _database.getAllAttempts();

  List<LocalTaskAttempt> getAttemptsForDay(DateTime day) {
    return _database
        .getAllAttempts()
        .where((a) => _sameDay(a.triggeredAt, day))
        .toList();
  }

  LocalStreak getStreak() => _database.getStreak();

  int getTotalXp() => _database.getTotalXP();

  int getGraceTokens() => _database.getGraceTokens();

  bool useGraceToken() => _database.useGraceToken();

  Set<String> getUnlockedAchievements() => _database.getUnlockedAchievements();

  void unlockAchievement(String code) => _database.unlockAchievement(code);

  void awardXp(int amount, String reason) {
    _database.awardXP(
        taskId: 'system',
        attemptId: 'achieve-${DateTime.now().millisecondsSinceEpoch}',
        amount: amount);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
