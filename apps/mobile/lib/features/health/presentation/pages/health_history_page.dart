// Habitat Health Multi-Day History Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../domain/repositories/health_repository.dart';
import '../../domain/services/health_service.dart';
import '../../domain/services/meal_service.dart';
import '../../domain/services/nap_service.dart';
import '../../domain/services/water_service.dart';
import '../widgets/health_history.dart';

class HealthHistoryPage extends StatefulWidget {
  const HealthHistoryPage({super.key});

  @override
  State<HealthHistoryPage> createState() => _HealthHistoryPageState();
}

class _HealthHistoryPageState extends State<HealthHistoryPage> {
  late final HealthService _healthService;

  @override
  void initState() {
    super.initState();
    final db = LocalDatabase.instance;
    final repo = HealthRepository(db);
    _healthService = HealthService(
      waterService: WaterService(repo),
      mealService: MealService(repo),
      napService: NapService(repo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = _healthService.getMultiDayHistory(7);

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('HEALTH HISTORY'),
        backgroundColor: HabitatTheme.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PAST 7 DAYS SUMMARY',
                style: TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: HabitatTheme.youngLeaf,
                ),
              ),
              const SizedBox(height: 12),
              HealthHistory(history: history),
            ],
          ),
        ),
      ),
    );
  }
}
