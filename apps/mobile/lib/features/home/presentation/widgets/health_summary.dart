// Habitat Health Snapshot Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/home_state_model.dart';

class HealthSummaryCard extends StatelessWidget {
  final HealthSummary summary;
  final VoidCallback? onOpenHealth;

  const HealthSummaryCard({
    super.key,
    required this.summary,
    this.onOpenHealth,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'Health Today: Water ${summary.waterMilliliters} of ${summary.waterTargetMilliliters} milliliters. '
          'Meals ${summary.mealsLogged} of ${summary.mealTarget}. '
          'Nap ${summary.napRunning ? "currently active" : "${summary.napMinutes} minutes"}.',
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
                    Icon(Icons.favorite_border,
                        size: 16, color: HabitatTheme.youngLeaf),
                    SizedBox(width: 8),
                    Text(
                      'HEALTH TODAY',
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
                if (summary.napRunning)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: HabitatTheme.growthGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bedtime,
                            size: 12, color: HabitatTheme.growthGreen),
                        SizedBox(width: 4),
                        Text(
                          'NAP ACTIVE',
                          style: TextStyle(
                            fontFamily: HabitatTheme.fontHeading,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: HabitatTheme.growthGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 3 Health Metrics Grid / Row
            Row(
              children: [
                // 1. Water
                Expanded(
                  child: _buildHealthTile(
                    icon: Icons.water_drop_outlined,
                    label: 'Water',
                    value:
                        '${summary.waterMilliliters}/${summary.waterTargetMilliliters} ml',
                    progress: summary.waterPercentage,
                  ),
                ),
                const SizedBox(width: 10),

                // 2. Meals
                Expanded(
                  child: _buildHealthTile(
                    icon: Icons.restaurant_outlined,
                    label: 'Meals',
                    value: '${summary.mealsLogged}/${summary.mealTarget}',
                    progress: summary.mealsPercentage,
                  ),
                ),
                const SizedBox(width: 10),

                // 3. Nap
                Expanded(
                  child: _buildHealthTile(
                    icon: Icons.bedtime_outlined,
                    label: 'Nap',
                    value: summary.napRunning
                        ? 'Running'
                        : '${summary.napMinutes} min',
                    progress: summary.napRunning ? 1.0 : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Navigation Button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onOpenHealth,
                icon: const Icon(Icons.spa_outlined, size: 16),
                label: const Text('View Health & Wellness'),
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

  Widget _buildHealthTile({
    required IconData icon,
    required String label,
    required String value,
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HabitatTheme.surfaceSecondary.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: HabitatTheme.growthGreen),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: HabitatTheme.fontBody,
              fontSize: 11,
              color: HabitatTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: HabitatTheme.fontHeading,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  HabitatTheme.growthGreen,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
