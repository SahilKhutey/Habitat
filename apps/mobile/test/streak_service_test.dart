// Habitat Streak Service Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/progress/domain/repositories/progress_repository.dart';
import 'package:habitat_mobile/features/progress/domain/services/streak_service.dart';

void main() {
  late LocalDatabase db;
  late StreakService streakService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    streakService = StreakService(ProgressRepository(db));
  });

  group('StreakService Unit Tests', () {
    test('getStreak() provides consistency metrics and stage motto', () {
      final initialStreak = streakService.getStreak();
      expect(initialStreak.currentStreak, equals(0));
      expect(initialStreak.stageMotto, equals('Sprout Stage'));
      expect(initialStreak.graceTokens, equals(1));
      expect(initialStreak.recentWeekAdherence.length, equals(7));

      // Advance streak via LocalDatabase
      db.updateStreak();

      final updated = streakService.getStreak();
      expect(updated.currentStreak, equals(1));
      expect(updated.longestStreak, equals(1));
    });

    test('useGraceToken() consumes available protection token', () {
      expect(streakService.getStreak().graceTokens, equals(1));

      final success = streakService.useGraceToken();
      expect(success, isTrue);
      expect(streakService.getStreak().graceTokens, equals(0));

      final secondAttempt = streakService.useGraceToken();
      expect(secondAttempt, isFalse);
    });
  });
}
