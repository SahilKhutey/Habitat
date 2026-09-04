// Habitat Streak Card Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/streak_model.dart';

class StreakCard extends StatelessWidget {
  final StreakModel streak;
  final VoidCallback? onOpenDetails;

  const StreakCard({
    super.key,
    required this.streak,
    this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'DISCIPLINE STREAK',
                    style: const TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
              if (onOpenDetails != null)
                InkWell(
                  onTap: onOpenDetails,
                  child: const Row(
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 16, color: Colors.orangeAccent),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Big Counter & Best
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔥 ${streak.currentStreak} Days',
                    style: const TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stage: ${streak.stageMotto} • Best: ${streak.longestStreak} days',
                    style: const TextStyle(
                      fontFamily: HabitatTheme.fontBody,
                      fontSize: 12,
                      color: HabitatTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: HabitatTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: HabitatTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield,
                        size: 14, color: HabitatTheme.youngLeaf),
                    const SizedBox(width: 4),
                    Text(
                      '${streak.graceTokens} Grace Token${streak.graceTokens == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontFamily: HabitatTheme.fontHeading,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: HabitatTheme.youngLeaf,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 7-Day Adherence Dot Markers Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(streak.recentWeekAdherence.length, (index) {
              final val = streak.recentWeekAdherence[index];
              const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: val == true
                          ? HabitatTheme.habitatGreen
                          : val == false
                              ? Colors.red.withOpacity(0.2)
                              : HabitatTheme.surfaceSecondary,
                      border: Border.all(
                        color: val == true
                            ? HabitatTheme.growthGreen
                            : val == false
                                ? Colors.redAccent
                                : HabitatTheme.surfaceBorder,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      val == true
                          ? '✓'
                          : val == false
                              ? '×'
                              : '○',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: val == true
                            ? HabitatTheme.growthGreen
                            : val == false
                                ? Colors.redAccent
                                : HabitatTheme.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayLabels[index],
                    style: const TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 10,
                      color: HabitatTheme.textSecondary,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
