// Habitat Today's Progress Card Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/daily_summary.dart';

class TodayProgressCard extends StatelessWidget {
  final DailyProgressSummaryModel summary;
  final VoidCallback? onTapDetails;

  const TodayProgressCard({
    super.key,
    required this.summary,
    this.onTapDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HabitatTheme.growthGreen.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline,
                      color: HabitatTheme.growthGreen, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "TODAY'S DISCIPLINE SCORE",
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: HabitatTheme.youngLeaf,
                    ),
                  ),
                ],
              ),
              if (onTapDetails != null)
                InkWell(
                  onTap: onTapDetails,
                  child: const Row(
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: HabitatTheme.growthGreen,
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 16, color: HabitatTheme.growthGreen),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Radial / Percentage Circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HabitatTheme.habitatGreen,
                  border: Border.all(color: HabitatTheme.growthGreen, width: 3),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${summary.completionPercentage}%',
                  style: const TextStyle(
                    fontFamily: HabitatTheme.fontHeading,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.completedCount} / ${summary.scheduledCount} Disciplines Completed',
                      style: const TextStyle(
                        fontFamily: HabitatTheme.fontHeading,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.scheduledCount == 0
                          ? 'No scheduled commitments today'
                          : summary.completedCount == summary.scheduledCount
                              ? 'All daily disciplines satisfied cleanly!'
                              : '${summary.missedCount} discipline remaining today',
                      style: const TextStyle(
                        fontFamily: HabitatTheme.fontBody,
                        fontSize: 12,
                        color: HabitatTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: summary.completionRatio,
              minHeight: 8,
              backgroundColor: HabitatTheme.surfaceSecondary,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(HabitatTheme.growthGreen),
            ),
          ),
        ],
      ),
    );
  }
}
