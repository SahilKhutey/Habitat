// Badges & Achievements Trophy Case Screen
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class BadgesGalleryScreen extends StatelessWidget {
  const BadgesGalleryScreen({super.key});

  final List<Map<String, dynamic>> _badges = const [
    {
      'title': 'First Step to Order',
      'desc': 'Complete your first physical discipline mission.',
      'icon': Icons.shield_moon,
      'isUnlocked': true,
      'reward': '+50 XP',
    },
    {
      'title': '7-Day Iron Will',
      'desc': 'Maintain an unbroken 7-day streak.',
      'icon': Icons.local_fire_department,
      'isUnlocked': true,
      'reward': '+100 XP',
    },
    {
      'title': '30-Day Spartan',
      'desc': '30 consecutive days without breaking discipline.',
      'icon': Icons.military_tech,
      'isUnlocked': false,
      'reward': '+500 XP',
    },
    {
      'title': 'Zero Hesitation',
      'desc': 'Earn 5 Instant Action Speed Bonuses under 120s.',
      'icon': Icons.bolt,
      'isUnlocked': false,
      'reward': '+150 XP',
    },
    {
      'title': 'Grace Vault Guardian',
      'desc': 'Accumulate maximum capacity of 3 Grace Tokens.',
      'icon': Icons.security,
      'isUnlocked': false,
      'reward': '+75 XP',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('ACHIEVEMENTS & TROPHIES'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.xl),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.85,
        ),
        itemCount: _badges.length,
        itemBuilder: (context, index) {
          final b = _badges[index];
          final isUnlocked = b['isUnlocked'] as bool;

          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.radiusLarge,
              border: Border.all(
                color: isUnlocked ? AppColors.amberFocus : Colors.white12,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  b['icon'] as IconData,
                  color: isUnlocked ? AppColors.amberFocus : Colors.white24,
                  size: 48,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  b['title'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.white : Colors.white38,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  b['desc'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: isUnlocked ? Colors.white70 : Colors.white24,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  b['reward'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? AppColors.emeraldVictory : Colors.white24,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
