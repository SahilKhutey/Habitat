// Habitat Streak Service & Grace Recovery Engine
import '../models/streak_model.dart';
import '../repositories/progress_repository.dart';

class StreakService {
  final ProgressRepository _repository;

  StreakService(this._repository);

  StreakModel getStreak() {
    final rawStreak = _repository.getStreak();
    final graceTokens = _repository.getGraceTokens();
    final stageMotto = _resolveStageMotto(rawStreak.currentStreak);

    // Calculate recent 7-day adherence (Monday to Sunday)
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final adherence = <bool?>[];

    for (int i = 0; i < 7; i++) {
      final day = DateTime(monday.year, monday.month, monday.day + i);
      if (day.isAfter(now)) {
        adherence.add(null); // Future day
      } else {
        final attempts = _repository.getAttemptsForDay(day);
        final hasCompleted = attempts.any((a) => a.status == 'COMPLETED');
        adherence.add(hasCompleted);
      }
    }

    return StreakModel(
      currentStreak: rawStreak.currentStreak,
      longestStreak: rawStreak.longestStreak,
      lastCompletedDate: rawStreak.lastCompletedDate,
      graceTokens: graceTokens,
      stageMotto: stageMotto,
      recentWeekAdherence: adherence,
    );
  }

  bool useGraceToken() {
    return _repository.useGraceToken();
  }

  String _resolveStageMotto(int streakDays) {
    if (streakDays >= 21) return 'Ancient Forest Stage';
    if (streakDays >= 7) return 'Canopy Stage';
    if (streakDays >= 3) return 'Sapling Stage';
    return 'Sprout Stage';
  }
}
