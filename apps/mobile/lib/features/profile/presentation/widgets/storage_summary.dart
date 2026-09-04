// Habitat Storage Breakdown Summary Widget
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/storage_info.dart';

class StorageSummary extends StatelessWidget {
  final StorageInfoModel info;

  const StorageSummary({super.key, required this.info});

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
              const Text(
                'LOCAL STORAGE USED',
                style: TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: HabitatTheme.youngLeaf,
                ),
              ),
              Text(
                info.formattedTotal,
                style: const TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRow('Tasks & Actions Database', info.formattedTasks,
              HabitatTheme.growthGreen),
          const SizedBox(height: 10),
          _buildRow('Health & Hydration Logs', info.formattedHealth,
              const Color(0xFF4CC9F0)),
          const SizedBox(height: 10),
          _buildRow('Progress & XP History', info.formattedProgress,
              Colors.orangeAccent),
          const SizedBox(height: 10),
          _buildRow('User Profile & Preferences', info.formattedProfile,
              HabitatTheme.youngLeaf),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    fontFamily: HabitatTheme.fontBody,
                    fontSize: 12,
                    color: HabitatTheme.textSecondary)),
          ],
        ),
        Text(value,
            style: const TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ],
    );
  }
}
