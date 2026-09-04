// Habitat Progress Page Widget Tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/core/theme/habitat_theme.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/progress/application/progress_controller.dart';
import 'package:habitat_mobile/features/progress/domain/repositories/progress_repository.dart';
import 'package:habitat_mobile/features/progress/domain/services/achievement_service.dart';
import 'package:habitat_mobile/features/progress/domain/services/daily_summary_service.dart';
import 'package:habitat_mobile/features/progress/domain/services/progress_service.dart';
import 'package:habitat_mobile/features/progress/domain/services/streak_service.dart';
import 'package:habitat_mobile/features/progress/domain/services/weekly_summary_service.dart';
import 'package:habitat_mobile/features/progress/presentation/pages/progress_page.dart';
import 'package:habitat_mobile/features/progress/presentation/widgets/daily_graph.dart';
import 'package:habitat_mobile/features/progress/presentation/widgets/date_range_selector.dart';
import 'package:habitat_mobile/features/progress/presentation/widgets/streak_card.dart';
import 'package:habitat_mobile/features/progress/presentation/widgets/today_progress_card.dart';

void main() {
  late LocalDatabase db;
  late ProgressRepository repo;
  late DailySummaryService daily;
  late WeeklySummaryService weekly;
  late StreakService streak;
  late AchievementService achievements;
  late ProgressService progressService;
  late ProgressController controller;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    repo = ProgressRepository(db);
    daily = DailySummaryService(repo);
    weekly = WeeklySummaryService(daily);
    streak = StreakService(repo);
    achievements = AchievementService(repo);
    progressService = ProgressService(
      repository: repo,
      dailyService: daily,
      weeklyService: weekly,
      streakService: streak,
      achievementService: achievements,
    );
    controller =
        ProgressController(progressService: progressService, database: db);
  });

  tearDown(() {
    controller.dispose();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      theme: HabitatTheme.darkTheme,
      home: ProgressPage(controller: controller),
    );
  }

  group('ProgressPage Widget Tests', () {
    testWidgets(
        'renders master progress hub with header, selector, cards, and streak',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('DISCIPLINE PROGRESS'), findsOneWidget);
      expect(find.byType(DateRangeSelector), findsOneWidget);
      expect(find.byType(TodayProgressCard), findsOneWidget);
      expect(find.byType(DailyGraph), findsOneWidget);
      expect(find.byType(StreakCard), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('WEEK'), findsOneWidget);
      expect(find.text('MONTH'), findsOneWidget);
    });

    testWidgets('switching timeframe chip to WEEK updates view dynamically',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final weekChip = find.text('WEEK');
      expect(weekChip, findsOneWidget);

      await tester.tap(weekChip);
      await tester.pumpAndSettle();

      expect(controller.selectedTimeframe, equals('WEEK'));
      expect(find.text('Total Done'), findsOneWidget);
      expect(find.text('Best Day'), findsOneWidget);
    });
  });
}
