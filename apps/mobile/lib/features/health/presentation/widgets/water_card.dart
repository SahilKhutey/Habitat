// Habitat Water Intake Card Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/water_entry.dart';

class WaterCard extends StatelessWidget {
  final WaterSummaryModel water;
  final ValueChanged<int> onAddPreset;
  final VoidCallback? onOpenDetails;

  const WaterCard({
    super.key,
    required this.water,
    required this.onAddPreset,
    this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (water.progressPercentage * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4CC9F0).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CC9F0).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.water_drop, color: Color(0xFF4CC9F0), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'HYDRATION TRACKER',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (onOpenDetails != null)
                TextButton(
                  onPressed: onOpenDetails,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4CC9F0),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: Color(0xFF4CC9F0)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Total Display & Target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${water.consumedMilliliters} ml',
                style: const TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                '$percentage% of ${water.targetMilliliters} ml goal',
                style: const TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4CC9F0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: water.progressPercentage,
              minHeight: 8,
              backgroundColor: HabitatTheme.surfaceSecondary,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CC9F0)),
            ),
          ),
          const SizedBox(height: 16),

          // Quick-Add Presets Row
          Row(
            children: [
              _buildPresetButton('+250 ml', 250),
              const SizedBox(width: 8),
              _buildPresetButton('+500 ml', 500),
              const SizedBox(width: 8),
              _buildPresetButton('+750 ml', 750),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, int amount) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => onAddPreset(amount),
        style: ElevatedButton.styleFrom(
          backgroundColor: HabitatTheme.surfaceSecondary,
          foregroundColor: const Color(0xFF4CC9F0),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: const Color(0xFF4CC9F0).withOpacity(0.3)),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: HabitatTheme.fontHeading,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
