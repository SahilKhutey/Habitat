// Habitat Daily Summary Service Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/progress/domain/repositories/progress_repository.dart';
import 'package:habitat_mobile/features/progress/domain/services/daily_summary_service.dart';

void main() {
  late LocalDatabase db;
  late DailySummaryService dailyService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    dailyService = DailySummaryService(ProgressRepository(db));
  });

  group('DailySummaryService Unit Tests', () {
    test('getDailySummary() computes completed ratio and percentage', () {
      final now = DateTime.now();

      // Record 2 attempts (1 COMPLETED, 1 FAILED)
      db.recordAttempt(LocalTaskAttempt(
        id: 'att-1',
        taskId: 'task-brush',
        alarmId: 'alarm-1',
        attemptNumber: 1,
        status: 'COMPLETED',
        triggeredAt: now,
      ));

      db.recordAttempt(LocalTaskAttempt(
        id: 'att-2',
        taskId: 'task-pushups',
        alarmId: 'alarm-2',
        attemptNumber: 1,
        status: 'FAILED',
        triggeredAt: now,
      ));

      final summary = dailyService.getDailySummary(now);

      expect(summary.completedCount, equals(1));
      expect(summary.failedCount, equals(1));
      expect(summary.completedTaskTitles, contains('Brush Teeth'));
      expect(summary.hasData, isTrue);
    });

    test('no-data distinction on future dates', () {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final summary = dailyService.getDailySummary(futureDate);

      expect(summary.scheduledCount, equals(0));
      expect(summary.completedCount, equals(0));
      expect(summary.hasData, isFalse);
    });
  });
}
