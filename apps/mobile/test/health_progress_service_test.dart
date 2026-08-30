// Habitat Health & Progress Unified Data Integration Tests (Phase 16)
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/core/health/health_progress_service.dart';
import 'package:habitat_mobile/database/local_database.dart';

void main() {
  late LocalDatabase db;
  late HealthProgressService service;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    service = HealthProgressService(database: db);
  });

  group('HealthProgressService Phase 16 Tests', () {
    test('16.1: Water logging aggregates milliliters and converts to liters accurately', () {
      expect(service.todayWaterLiters, equals(0.0));

      service.addWaterMl(500);
      expect(service.todayWaterLiters, equals(0.5));

      service.addWaterMl(750);
      service.addWaterMl(250);
      expect(service.todayWaterLiters, equals(1.5));
    });

    test('16.2: Meal logging records breakfast, lunch, snacks, dinner', () {
      expect(service.todayMealCount, equals(0));

      service.logMeal('BREAKFAST');
      expect(service.todayMealCount, equals(1));

      service.logMeal('LUNCH');
      expect(service.todayMealCount, equals(2));
    });

    test('16.3: Nap logging records duration in minutes', () {
      expect(service.todayNapMinutes, equals(0));

      service.logNap(const Duration(minutes: 30));
      expect(service.todayNapMinutes, equals(30));

      service.logNap(const Duration(minutes: 20));
      expect(service.todayNapMinutes, equals(50));
    });

    test('16.4: Unified summary combines health, XP, streak, and daily completions', () {
      service.addWaterMl(500);
      service.logMeal('BREAKFAST');
      service.logNap(const Duration(minutes: 30));

      final summary = service.getTodaySummary();
      expect(summary.waterLiters, equals(0.5));
      expect(summary.mealCount, equals(1));
      expect(summary.napMinutes, equals(30));
      expect(summary.dailyCompletions.isNotEmpty, isTrue);
      expect(summary.dailyWater.isNotEmpty, isTrue);
    });

    test('16.5: 7-day daily completions aggregate completed task attempts', () {
      final task = LocalTask(
        id: 'task_001',
        title: 'Morning Pushups',
        category: 'PHYSICAL',
        taskType: 'VIDEO',
        requiresVideo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = LocalTaskAttempt(
        id: 'att_001',
        taskId: 'task_001',
        alarmId: 'alarm_001',
        attemptNumber: 1,
        status: 'COMPLETED',
        triggeredAt: DateTime.now(),
        completedAt: DateTime.now(),
      );
      db.saveAttempt(attempt);

      final completions = service.dailyCompletions;
      final todayKey = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, "0")}-${DateTime.now().day.toString().padLeft(2, "0")}';
      expect(completions[todayKey], equals(1));
    });
  });
}
