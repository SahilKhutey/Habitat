// Habitat Achievement Service Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/progress/domain/repositories/progress_repository.dart';
import 'package:habitat_mobile/features/progress/domain/services/achievement_service.dart';

void main() {
  late LocalDatabase db;
  late AchievementService achievementService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    achievementService = AchievementService(ProgressRepository(db));
  });

  group('AchievementService Unit Tests', () {
    test('getAllAchievements() returns canonical achievements catalog', () {
      final achievements = achievementService.getAllAchievements();
      expect(achievements.length, greaterThanOrEqualTo(7));
      expect(achievements.any((a) => a.code == 'FIRST_STEP'), isTrue);
      expect(achievements.any((a) => a.code == 'IRON_MOMENTUM'), isTrue);
    });

    test('evaluateAndUnlock() unlocks FIRST_STEP on task completion', () {
      final now = DateTime.now();

      db.recordAttempt(LocalTaskAttempt(
        id: 'att-first',
        taskId: 'task-brush',
        alarmId: 'alarm-1',
        attemptNumber: 1,
        status: 'COMPLETED',
        triggeredAt: now,
      ));

      achievementService.evaluateAndUnlock();

      final achievements = achievementService.getAllAchievements();
      final firstStep = achievements.firstWhere((a) => a.code == 'FIRST_STEP');
      expect(firstStep.isUnlocked, isTrue);
    });
  });
}
