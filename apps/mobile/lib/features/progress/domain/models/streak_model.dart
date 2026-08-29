// Habitat Streak Domain Model
import 'package:flutter/foundation.dart';

@immutable
class StreakModel {
  final int currentStreak;
  final int longestStreak;
  final String lastCompletedDate;
  final int graceTokens;
  final String stageMotto;
  final List<bool?> recentWeekAdherence; // 7 days: true = completed, false = missed, null = future/pending

  const StreakModel({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletedDate,
    this.graceTokens = 1,
    this.stageMotto = 'Sprout Stage',
    this.recentWeekAdherence = const [true, true, true, true, true, true, true],
  });

  bool get isStreakActive => currentStreak > 0;
}
