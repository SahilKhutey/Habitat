// Habitat Weekly Summary Service Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/progress/domain/repositories/progress_repository.dart';
import 'package:habitat_mobile/features/progress/domain/services/daily_summary_service.dart';
import 'package:habitat_mobile/features/progress/domain/services/weekly_summary_service.dart';

void main() {
  late LocalDatabase db;
  late WeeklySummaryService weeklyService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    final repo = ProgressRepository(db);
    weeklyService = WeeklySummaryService(DailySummaryService(repo));
  });

  group('WeeklySummaryService Unit Tests', () {
    test('getWeeklySummary() returns 7-day Monday through Sunday breakdown', () {
      final now = DateTime.now();

      // Record a completion today
      db.recordAttempt(LocalTaskAttempt(
        id: 'att-10',
        taskId: 'task-brush',
        alarmId: 'alarm-1',
        attemptNumber: 1,
        status: 'COMPLETED',
        triggeredAt: now,
      ));

      final week = weeklyService.getWeeklySummary(now);

      expect(week.days.length, equals(7));
      expect(week.days.first.dayName, equals('Mon'));
      expect(week.days.last.dayName, equals('Sun'));
      expect(week.totalCompleted, greaterThanOrEqualTo(1));
      expect(week.bestDay, isNotEmpty);
      expect(week.lowestDay, isNotEmpty);
    });
  });
}
