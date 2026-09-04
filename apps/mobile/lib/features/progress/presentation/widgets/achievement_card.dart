// Habitat Achievement Card Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/achievement_model.dart';

class AchievementCard extends StatelessWidget {
  final AchievementModel achievement;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? HabitatTheme.growthGreen.withOpacity(0.4)
              : HabitatTheme.surfaceBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Trophy/Badge Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? HabitatTheme.habitatGreen
                        : HabitatTheme.surfaceSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUnlocked
                          ? HabitatTheme.growthGreen
                          : HabitatTheme.surfaceBorder,
                    ),
                  ),
                  child: Icon(
                    _resolveIcon(achievement.iconName),
                    color: isUnlocked
                        ? HabitatTheme.growthGreen
                        : HabitatTheme.textMuted,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            achievement.name,
                            style: const TextStyle(
                              fontFamily: HabitatTheme.fontHeading,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? HabitatTheme.growthGreen.withOpacity(0.2)
                                  : HabitatTheme.surfaceSecondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+${achievement.xpReward} XP',
                              style: TextStyle(
                                fontFamily: HabitatTheme.fontHeading,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isUnlocked
                                    ? HabitatTheme.growthGreen
                                    : HabitatTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        achievement.description,
                        style: const TextStyle(
                          fontFamily: HabitatTheme.fontBody,
                          fontSize: 12,
                          color: HabitatTheme.textSecondary,
                        ),
                      ),
                      if (!isUnlocked && achievement.progressPercent > 0) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: achievement.progressPercent,
                            minHeight: 4,
                            backgroundColor: HabitatTheme.surfaceSecondary,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                HabitatTheme.youngLeaf),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _resolveIcon(String name) => switch (name) {
        'emoji_events' => Icons.emoji_events_outlined,
        'local_fire_department' => Icons.local_fire_department_outlined,
        'military_tech' => Icons.military_tech_outlined,
        'stars' => Icons.stars_outlined,
        'bolt' => Icons.bolt_outlined,
        'water_drop' => Icons.water_drop_outlined,
        'bedtime' => Icons.bedtime_outlined,
        _ => Icons.workspace_premium_outlined,
      };
}
