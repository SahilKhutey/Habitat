// Phase 2 Foundation Home Screen
import 'package:flutter/material.dart';
import '../../../../packages/design_system/lib/design_system.dart';

class HomeFoundationScreen extends StatelessWidget {
  const HomeFoundationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('DISCIPLINE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Design System Showcase',
            onPressed: () {
              Navigator.of(context).pushNamed('/design-system');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting & Header
            Text(
              'Good morning 👋',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text("Today's Discipline", style: AppTypography.displayMedium),
            const SizedBox(height: AppSpacing.xl),

            // Progress Summary Card
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('3 MISSIONS SCHEDULED', style: AppTypography.labelLarge),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.amberFocusSubtle,
                          borderRadius: AppRadii.radiusSmall,
                        ),
                        child: const Text(
                          '70% COMPLETED',
                          style: TextStyle(color: AppColors.amberFocus, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppProgressBar(progress: 0.70),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Next Mission Card
            const Text('NEXT COMMITMENT', style: AppTypography.labelMedium),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              borderColor: AppColors.amberFocus.withOpacity(0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.amberFocusSubtle,
                              borderRadius: AppRadii.radiusMedium,
                            ),
                            child: const Icon(Icons.fitness_center, color: AppColors.amberFocus, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('10 Morning Push-Ups', style: AppTypography.titleLarge),
                              Text('07:00 AM • Video Proof', style: AppTypography.bodySmall),
                            ],
                          ),
                        ],
                      ),
                      const Text('+25 XP', style: TextStyle(color: AppColors.emeraldVictory, fontWeight: FontWeight.w900, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton.primary(
                    label: 'VIEW MISSION DETAILS',
                    icon: Icons.arrow_forward,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening Mission Protocol...')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
