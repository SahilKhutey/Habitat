// Habitat Today's Task Summary Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/home_state_model.dart';

class TodaySummaryCard extends StatelessWidget {
  final DailyProgressSummary summary;
  final VoidCallback? onOpenTasks;

  const TodaySummaryCard({
    super.key,
    required this.summary,
    this.onOpenTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'Today\'s summary: ${summary.completedTasks} of ${summary.totalTasks} tasks completed. ${summary.completionPercentInt} percent done. ${summary.remainingTasks} remaining.',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: HabitatTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HabitatTheme.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.checklist_rtl,
                        size: 16, color: HabitatTheme.youngLeaf),
                    SizedBox(width: 8),
                    Text(
                      'TODAY',
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: HabitatTheme.habitatGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${summary.completionPercentInt}%',
                    style: const TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: HabitatTheme.growthGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Metrics Count Headline
            Text(
              '${summary.completedTasks} / ${summary.totalTasks} Tasks Complete',
              style: const TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: summary.completionPercentage,
                minHeight: 8,
                backgroundColor: HabitatTheme.surfaceSecondary,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  HabitatTheme.growthGreen,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sub-metrics & Navigation Link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${summary.remainingTasks} remaining'
                  '${summary.missedTasks > 0 ? ' • ${summary.missedTasks} missed' : ''}',
                  style: const TextStyle(
                    fontFamily: HabitatTheme.fontBody,
                    fontSize: 12,
                    color: HabitatTheme.textSecondary,
                  ),
                ),
                InkWell(
                  onTap: onOpenTasks,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View all',
                          style: TextStyle(
                            fontFamily: HabitatTheme.fontHeading,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: HabitatTheme.growthGreen,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: HabitatTheme.growthGreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
