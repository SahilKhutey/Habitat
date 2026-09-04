// Habitat Dedicated Monthly Analytics Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/services/daily_summary_service.dart';
import '../../domain/services/monthly_summary_service.dart';
import '../../domain/services/weekly_summary_service.dart';
import '../widgets/weekly_graph.dart';

class MonthlyProgressPage extends StatefulWidget {
  const MonthlyProgressPage({super.key});

  @override
  State<MonthlyProgressPage> createState() => _MonthlyProgressPageState();
}

class _MonthlyProgressPageState extends State<MonthlyProgressPage> {
  late final MonthlySummaryService _monthlyService;

  @override
  void initState() {
    super.initState();
    final repo = ProgressRepository(LocalDatabase.instance);
    _monthlyService =
        MonthlySummaryService(WeeklySummaryService(DailySummaryService(repo)));
  }

  @override
  Widget build(BuildContext context) {
    final monthly = _monthlyService.getMonthlySummary();

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: Text('${monthly.monthName} Overview'.toUpperCase()),
        backgroundColor: HabitatTheme.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WeeklyGraph(monthlySummary: monthly),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: HabitatTheme.surfacePrimary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: HabitatTheme.growthGreen.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Monthly Adherence',
                        '${monthly.averageCompletionPercentage.toInt()}%'),
                    const Divider(
                        height: 20, color: HabitatTheme.surfaceBorder),
                    _buildSummaryRow(
                        'Total Completed Actions', '${monthly.totalCompleted}'),
                    const Divider(
                        height: 20, color: HabitatTheme.surfaceBorder),
                    _buildSummaryRow(
                        'Best Consistency Window', monthly.bestWeek),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: HabitatTheme.fontBody,
            fontSize: 13,
            color: HabitatTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: HabitatTheme.fontHeading,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
