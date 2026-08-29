// Habitat Consistency & Streak Snapshot Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/home_state_model.dart';

class StreakCard extends StatelessWidget {
  final StreakSummary summary;
  final VoidCallback? onOpenProgress;

  const StreakCard({
    super.key,
    required this.summary,
    this.onOpenProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'Consistency Streak: ${summary.currentStreak} days streak. Best streak: ${summary.bestStreak} days.',
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
                    Icon(Icons.local_fire_department,
                        size: 16, color: HabitatTheme.growthGreen),
                    SizedBox(width: 8),
                    Text(
                      'CONSISTENCY',
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
                  'Best: ${summary.bestStreak} days',
                  style: const TextStyle(
                    fontFamily: HabitatTheme.fontBody,
                    fontSize: 11,
                    color: HabitatTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Streak Headline
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: HabitatTheme.habitatGreen.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: HabitatTheme.growthGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.currentStreak} Day Streak',
                      style: const TextStyle(
                        fontFamily: HabitatTheme.fontHeading,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _streakMessage(summary.currentStreak),
                      style: const TextStyle(
                        fontFamily: HabitatTheme.fontBody,
                        fontSize: 12,
                        color: HabitatTheme.youngLeaf,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Navigation Link
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onOpenProgress,
                icon: const Icon(Icons.workspace_premium_outlined, size: 16),
                label: const Text('View Streak History & Milestones'),
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

  String _streakMessage(int streak) {
    if (streak == 0) return 'Start your streak with today\'s first action.';
    if (streak == 1) return 'Great start! Build the habit again tomorrow.';
    if (streak < 7) return 'Building daily momentum. Keep going!';
    if (streak < 21) return 'Impressive discipline! Forest canopy growing.';
    return 'Master level consistency. Unstoppable.';
  }
}
