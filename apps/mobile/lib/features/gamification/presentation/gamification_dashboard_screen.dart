// Gamification Dashboard Screen (Level Ring, XP, Streaks & Grace Vault)
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class GamificationDashboardScreen extends StatelessWidget {
  const GamificationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('DISCIPLINE ECONOMY & STATS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'XP Ledger Audit',
            onPressed: () {
              Navigator.of(context).pushNamed('/gamification/ledger');
            },
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Trophy Case',
            onPressed: () {
              Navigator.of(context).pushNamed('/gamification/badges');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level & XP Ring Centerpiece
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadii.radiusLarge,
                border:
                    Border.all(color: AppColors.amberFocus.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.amberFocus.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.amberFocus, width: 3),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('LVL',
                            style: TextStyle(
                                color: AppColors.amberFocus,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                        Text('4',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DISCIPLINE RANK',
                            style: AppTypography.labelSmall),
                        const SizedBox(height: 2),
                        const Text('Spartan Initiate',
                            style: AppTypography.titleLarge),
                        const SizedBox(height: AppSpacing.xs),
                        const ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          child: LinearProgressIndicator(
                            value: 0.68,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.amberFocus),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('680 / 1,000 XP (320 XP to Level 5)',
                            style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Streak & Grace Vault Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppRadii.radiusLarge,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.local_fire_department,
                                color: Colors.orange, size: 20),
                            SizedBox(width: 4),
                            Text('STREAK', style: AppTypography.labelSmall),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text('14 Days',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('Best: 21 Days', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppRadii.radiusLarge,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.security,
                                color: AppColors.emeraldVictory, size: 20),
                            SizedBox(width: 4),
                            Text('GRACE VAULT',
                                style: AppTypography.labelSmall),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text('2 / 3 Shields',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('Auto-saves missed days',
                            style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Daily Discipline Score
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadii.radiusLarge,
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('DAILY DISCIPLINE SCORE',
                          style: AppTypography.labelSmall),
                      SizedBox(height: 4),
                      Text('94 / 100',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.emeraldVictory)),
                      Text('Based on 00:45s avg resistance speed',
                          style: AppTypography.bodySmall),
                    ],
                  ),
                  const Icon(Icons.speed,
                      color: AppColors.emeraldVictory, size: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
