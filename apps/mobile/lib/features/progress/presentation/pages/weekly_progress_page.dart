// Habitat Dedicated Weekly Analytics Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/services/daily_summary_service.dart';
import '../../domain/services/weekly_summary_service.dart';
import '../widgets/daily_graph.dart';
import 'daily_progress_page.dart';

class WeeklyProgressPage extends StatefulWidget {
  const WeeklyProgressPage({super.key});

  @override
  State<WeeklyProgressPage> createState() => _WeeklyProgressPageState();
}

class _WeeklyProgressPageState extends State<WeeklyProgressPage> {
  late final WeeklySummaryService _weeklyService;

  @override
  void initState() {
    super.initState();
    final repo = ProgressRepository(LocalDatabase.instance);
    _weeklyService = WeeklySummaryService(DailySummaryService(repo));
  }

  @override
  Widget build(BuildContext context) {
    final week = _weeklyService.getWeeklySummary();

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('WEEKLY ANALYTICS'),
        backgroundColor: HabitatTheme.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DailyGraph(
                weekSummary: week,
                onSelectDay: (day) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => DailyProgressPage(date: day.date)),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Weekly Metrics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      title: 'TOTAL COMPLETED',
                      value: '${week.totalCompleted}',
                      subtitle: 'actions finished',
                      icon: Icons.check_circle_outline,
                      color: HabitatTheme.growthGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      title: 'AVERAGE SCORE',
                      value: '${week.averageCompletionPercentage.toInt()}%',
                      subtitle: 'daily adherence',
                      icon: Icons.trending_up,
                      color: HabitatTheme.youngLeaf,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      title: 'BEST DAY',
                      value: week.bestDay,
                      subtitle: 'peak consistency',
                      icon: Icons.star_border,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      title: 'LOWEST DAY',
                      value: week.lowestDay,
                      subtitle: 'room for recovery',
                      icon: Icons.replay,
                      color: HabitatTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HabitatTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: HabitatTheme.fontHeading,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontFamily: HabitatTheme.fontHeading,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: HabitatTheme.fontBody,
              fontSize: 11,
              color: HabitatTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
