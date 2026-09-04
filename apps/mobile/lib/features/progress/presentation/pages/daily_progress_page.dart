// Habitat Dedicated Daily Progress Breakdown Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/services/daily_summary_service.dart';
import '../widgets/today_progress_card.dart';

class DailyProgressPage extends StatefulWidget {
  final DateTime date;

  const DailyProgressPage({super.key, required this.date});

  @override
  State<DailyProgressPage> createState() => _DailyProgressPageState();
}

class _DailyProgressPageState extends State<DailyProgressPage> {
  late final DailySummaryService _dailyService;

  @override
  void initState() {
    super.initState();
    _dailyService =
        DailySummaryService(ProgressRepository(LocalDatabase.instance));
  }

  @override
  Widget build(BuildContext context) {
    final summary = _dailyService.getDailySummary(widget.date);

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: Text('${summary.dayName} Progress'.toUpperCase()),
        backgroundColor: HabitatTheme.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Progress Metric Card
              TodayProgressCard(summary: summary),
              const SizedBox(height: 24),

              // 2. Completed Disciplines Breakdown
              const Text(
                'COMPLETED DISCIPLINES',
                style: TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: HabitatTheme.youngLeaf,
                ),
              ),
              const SizedBox(height: 12),

              if (summary.completedTaskTitles.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: HabitatTheme.surfacePrimary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HabitatTheme.surfaceBorder),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'No completed discipline missions for this date.',
                    style: TextStyle(
                        color: HabitatTheme.textSecondary, fontSize: 13),
                  ),
                )
              else
                ...summary.completedTaskTitles.map((title) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: HabitatTheme.surfacePrimary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: HabitatTheme.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: HabitatTheme.growthGreen, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: HabitatTheme.fontHeading,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
