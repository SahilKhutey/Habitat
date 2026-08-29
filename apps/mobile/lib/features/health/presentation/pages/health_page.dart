// Habitat Health Master Overview Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../application/health_controller.dart';
import '../../application/nap_controller.dart';
import '../../domain/models/meal_entry.dart';
import '../../domain/repositories/health_repository.dart';
import '../../domain/services/health_service.dart';
import '../../domain/services/meal_service.dart';
import '../../domain/services/nap_service.dart';
import '../../domain/services/water_service.dart';
import '../widgets/health_summary_card.dart';
import '../widgets/meal_card.dart';
import '../widgets/nap_card.dart';
import '../widgets/water_card.dart';
import 'health_history_page.dart';
import 'meal_entry_page.dart';
import 'meals_page.dart';
import 'nap_page.dart';
import 'water_page.dart';

class HealthPage extends StatefulWidget {
  final HealthController? controller;

  const HealthPage({super.key, this.controller});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  late final HealthController _healthController;
  late final NapController _napController;
  late final WaterService _waterService;
  late final MealService _mealService;
  late final NapService _napService;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    final db = LocalDatabase.instance;
    final repo = HealthRepository(db);
    _waterService = WaterService(repo);
    _mealService = MealService(repo);
    _napService = NapService(repo);

    final healthService = HealthService(
      waterService: _waterService,
      mealService: _mealService,
      napService: _napService,
    );

    if (widget.controller != null) {
      _healthController = widget.controller!;
    } else {
      _healthController = HealthController(
        healthService: healthService,
        database: db,
      );
      _internalController = true;
    }

    _napController = NapController(
      napService: _napService,
      database: db,
    );
  }

  @override
  void dispose() {
    if (_internalController) {
      _healthController.dispose();
    }
    _napController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_healthController, _napController]),
      builder: (context, _) {
        final summary = _healthController.summary;

        return Scaffold(
          backgroundColor: HabitatTheme.background,
          appBar: AppBar(
            title: const Text('HEALTH TRACK'),
            backgroundColor: HabitatTheme.background,
            actions: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                tooltip: 'Health History',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HealthHistoryPage()),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Master Health Snapshot Card
                  HealthSummaryCard(
                    summary: summary,
                    onOpenWater: _openWaterPage,
                    onOpenMeals: _openMealsPage,
                    onOpenNap: _openNapPage,
                  ),
                  const SizedBox(height: 18),

                  // 2. Hydration Tracker Card
                  WaterCard(
                    water: summary.water,
                    onAddPreset: (amount) => _waterService.addWater(amount),
                    onOpenDetails: _openWaterPage,
                  ),
                  const SizedBox(height: 18),

                  // 3. Meal Nourishment Card
                  MealCard(
                    meals: summary.meals,
                    onLogMeal: _openMealEntryModal,
                    onOpenDetails: _openMealsPage,
                  ),
                  const SizedBox(height: 18),

                  // 4. Nap Recovery Card
                  NapCard(
                    nap: summary.nap,
                    runningTimer: _napController.formattedTimer,
                    onToggleNap: () {
                      if (summary.nap.isRunning) {
                        _napController.stopNap();
                      } else {
                        _napController.startNap();
                      }
                    },
                    onOpenDetails: _openNapPage,
                  ),
                  const SizedBox(height: 24),

                  // 5. History Footer Link
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HealthHistoryPage()),
                        );
                      },
                      icon: const Icon(Icons.history, size: 16, color: HabitatTheme.textSecondary),
                      label: const Text(
                        'View Multi-Day Health History →',
                        style: TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: HabitatTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openWaterPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WaterPage()),
    );
  }

  void _openMealsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MealsPage()),
    );
  }

  void _openNapPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NapPage()),
    );
  }

  void _openMealEntryModal(MealType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealEntryPage(initialType: type),
      ),
    );
  }
}
