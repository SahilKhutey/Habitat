// Habitat Multi-Week Trend Graph Widget
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/monthly_summary.dart';

class WeeklyGraph extends StatelessWidget {
  final MonthlyProgressSummaryModel monthlySummary;

  const WeeklyGraph({super.key, required this.monthlySummary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HabitatTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${monthlySummary.monthName.toUpperCase()} MONTHLY TREND',
                style: const TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: HabitatTheme.youngLeaf,
                ),
              ),
              Text(
                'Avg: ${monthlySummary.averageCompletionPercentage.toInt()}%',
                style: const TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: HabitatTheme.growthGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...List.generate(monthlySummary.weeks.length, (index) {
            final week = monthlySummary.weeks[index];
            final avg = week.averageCompletionPercentage.toInt();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Week ${index + 1}',
                        style: const TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$avg% (${week.totalCompleted} done)',
                        style: const TextStyle(
                          fontFamily: HabitatTheme.fontBody,
                          fontSize: 11,
                          color: HabitatTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (avg / 100.0).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: HabitatTheme.surfaceSecondary,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        avg >= 70 ? HabitatTheme.growthGreen : HabitatTheme.youngLeaf,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
