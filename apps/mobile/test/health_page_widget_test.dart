// Habitat Health Page Widget Tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/core/theme/habitat_theme.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/health/application/health_controller.dart';
import 'package:habitat_mobile/features/health/domain/repositories/health_repository.dart';
import 'package:habitat_mobile/features/health/domain/services/health_service.dart';
import 'package:habitat_mobile/features/health/domain/services/meal_service.dart';
import 'package:habitat_mobile/features/health/domain/services/nap_service.dart';
import 'package:habitat_mobile/features/health/domain/services/water_service.dart';
import 'package:habitat_mobile/features/health/presentation/pages/health_page.dart';
import 'package:habitat_mobile/features/health/presentation/widgets/health_summary_card.dart';
import 'package:habitat_mobile/features/health/presentation/widgets/meal_card.dart';
import 'package:habitat_mobile/features/health/presentation/widgets/nap_card.dart';
import 'package:habitat_mobile/features/health/presentation/widgets/water_card.dart';

void main() {
  late LocalDatabase db;
  late HealthRepository repo;
  late WaterService waterService;
  late MealService mealService;
  late NapService napService;
  late HealthService healthService;
  late HealthController controller;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    repo = HealthRepository(db);
    waterService = WaterService(repo);
    mealService = MealService(repo);
    napService = NapService(repo);
    healthService = HealthService(
      waterService: waterService,
      mealService: mealService,
      napService: napService,
    );
    controller = HealthController(healthService: healthService, database: db);
  });

  tearDown(() {
    controller.dispose();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      theme: HabitatTheme.darkTheme,
      home: HealthPage(controller: controller),
    );
  }

  group('HealthPage Widget Tests', () {
    testWidgets('renders all health cards and quick add buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('HEALTH TRACK'), findsOneWidget);
      expect(find.byType(HealthSummaryCard), findsOneWidget);
      expect(find.byType(WaterCard), findsOneWidget);
      expect(find.byType(MealCard), findsOneWidget);
      expect(find.byType(NapCard), findsOneWidget);
      expect(find.text('+250 ml'), findsOneWidget);
      expect(find.text('+500 ml'), findsOneWidget);
      expect(find.text('+750 ml'), findsOneWidget);
      expect(find.text('START NAP'), findsOneWidget);
    });

    testWidgets('tapping +250 ml water quick-add updates water total immediately', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final quickAddBtn = find.text('+250 ml');
      expect(quickAddBtn, findsOneWidget);

      await tester.tap(quickAddBtn);
      await tester.pumpAndSettle();

      expect(find.text('250 ml'), findsOneWidget);
      expect(controller.summary.water.consumedMilliliters, equals(250));
    });

    testWidgets('tapping START NAP starts active nap session and changes label to END NAP', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final startNapBtn = find.text('START NAP');
      expect(startNapBtn, findsOneWidget);

      await tester.tap(startNapBtn);
      await tester.pumpAndSettle();

      expect(find.text('END NAP'), findsOneWidget);
      expect(controller.summary.nap.isRunning, isTrue);
    });
  });
}
