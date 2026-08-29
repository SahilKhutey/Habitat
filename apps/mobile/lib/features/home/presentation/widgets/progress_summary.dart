// Habitat Daily Progress Summary Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/home_state_model.dart';

class ProgressSummaryCard extends StatelessWidget {
  final DailyProgressSummary summary;
  final StreakSummary streak;
  final VoidCallback? onOpenProgress;

  const ProgressSummaryCard({
    super.key,
    required this.summary,
    required this.streak,
    this.onOpenProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'Daily Progress: ${summary.completionPercentInt} percent completed. Stage: ${streak.stageMotto}.',
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
                    Icon(Icons.trending_up,
                        size: 16, color: HabitatTheme.youngLeaf),
                    SizedBox(width: 8),
                    Text(
                      'PROGRESS',
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
                Text(
                  streak.stageMotto,
                  style: const TextStyle(
                    fontFamily: HabitatTheme.fontHeading,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: HabitatTheme.growthGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Radial / Key Metrics Row
            Row(
              children: [
                // Circular Progress Ring
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: summary.completionPercentage,
                        strokeWidth: 6,
                        backgroundColor: HabitatTheme.surfaceSecondary,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          HabitatTheme.growthGreen,
                        ),
                      ),
                      Text(
                        '${summary.completionPercentInt}%',
                        style: const TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Metrics Breakdown
                Expanded(
                  child: Column(
                    children: [
                      _buildMetricRow(
                        'Completed',
                        '${summary.completedTasks}',
                        HabitatTheme.growthGreen,
                      ),
                      const SizedBox(height: 4),
                      _buildMetricRow(
                        'Remaining',
                        '${summary.remainingTasks}',
                        HabitatTheme.textSecondary,
                      ),
                      if (summary.missedTasks > 0) ...[
                        const SizedBox(height: 4),
                        _buildMetricRow(
                          'Missed',
                          '${summary.missedTasks}',
                          Colors.redAccent,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Navigation Button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onOpenProgress,
                icon: const Icon(Icons.analytics_outlined, size: 16),
                label: const Text('View Journey & Growth'),
                style: TextButton.styleFrom(
                  foregroundColor: HabitatTheme.youngLeaf,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: HabitatTheme.fontBody,
            fontSize: 12,
            color: HabitatTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: HabitatTheme.fontHeading,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
