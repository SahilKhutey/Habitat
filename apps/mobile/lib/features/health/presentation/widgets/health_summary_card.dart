// Habitat Health Summary Master Card Widget
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/health_summary.dart';

class HealthSummaryCard extends StatelessWidget {
  final HealthSummaryModel summary;
  final VoidCallback? onOpenWater;
  final VoidCallback? onOpenMeals;
  final VoidCallback? onOpenNap;

  const HealthSummaryCard({
    super.key,
    required this.summary,
    this.onOpenWater,
    this.onOpenMeals,
    this.onOpenNap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              const Row(
                children: [
                  Icon(Icons.favorite_outline, color: HabitatTheme.growthGreen, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "TODAY'S HEALTH SNAPSHOT",
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: HabitatTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SYNCED',
                  style: TextStyle(
                    fontFamily: HabitatTheme.fontHeading,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: HabitatTheme.youngLeaf,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // 1. Water Pillar
              Expanded(
                child: _buildMetricTile(
                  title: 'WATER',
                  value: '${summary.water.consumedLiters.toStringAsFixed(1)}L',
                  target: '${summary.water.targetLiters.toStringAsFixed(1)}L target',
                  icon: Icons.water_drop_outlined,
                  color: const Color(0xFF4CC9F0),
                  onTap: onOpenWater,
                ),
              ),
              const SizedBox(width: 8),

              // 2. Meals Pillar
              Expanded(
                child: _buildMetricTile(
                  title: 'MEALS',
                  value: '${summary.meals.loggedCount}/4',
                  target: 'meals logged',
                  icon: Icons.restaurant_outlined,
                  color: const Color(0xFFF72585),
                  onTap: onOpenMeals,
                ),
              ),
              const SizedBox(width: 8),

              // 3. Nap Pillar
              Expanded(
                child: _buildMetricTile(
                  title: 'REST / NAP',
                  value: summary.nap.isRunning ? 'RUNNING' : summary.nap.formattedDuration,
                  target: summary.nap.isRunning ? 'Active session' : 'rest logged',
                  icon: Icons.bedtime_outlined,
                  color: const Color(0xFF7209B7),
                  onTap: onOpenNap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String target,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: HabitatTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HabitatTheme.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              target,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: HabitatTheme.fontBody,
                fontSize: 10,
                color: HabitatTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
