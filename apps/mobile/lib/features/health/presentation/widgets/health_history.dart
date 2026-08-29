// Habitat Health History List Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/health_summary.dart';

class HealthHistory extends StatelessWidget {
  final List<HealthSummaryModel> history;

  const HealthHistory({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: history.map((daySummary) {
        final dateLabel = _formatDate(daySummary.date);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HabitatTheme.surfacePrimary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HabitatTheme.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: const TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPillarMetric(
                    label: 'Water',
                    value: '${daySummary.water.consumedLiters.toStringAsFixed(1)} L',
                    color: const Color(0xFF4CC9F0),
                    icon: Icons.water_drop_outlined,
                  ),
                  _buildPillarMetric(
                    label: 'Meals',
                    value: '${daySummary.meals.loggedCount}/4',
                    color: const Color(0xFFF72585),
                    icon: Icons.restaurant_outlined,
                  ),
                  _buildPillarMetric(
                    label: 'Nap / Rest',
                    value: daySummary.nap.formattedDuration,
                    color: const Color(0xFF7209B7),
                    icon: Icons.bedtime_outlined,
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPillarMetric({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: HabitatTheme.fontBody,
                fontSize: 10,
                color: HabitatTheme.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
      return 'Yesterday';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
