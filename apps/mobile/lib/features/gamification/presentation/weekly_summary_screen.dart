// Tactical Weekly Discipline Summary Screen & Behavioral Insights
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class WeeklySummaryScreen extends StatelessWidget {
  final int tasksCompleted;
  final int tasksAttempted;
  final int completionRate;
  final int currentStreak;
  final int xpEarned;
  final String bestDay;
  final String insight;

  const WeeklySummaryScreen({
    super.key,
    this.tasksCompleted = 32,
    this.tasksAttempted = 38,
    this.completionRate = 84,
    this.currentStreak = 12,
    this.xpEarned = 420,
    this.bestDay = 'Tuesday',
    this.insight =
        'You completed your morning missions more consistently than evening missions this week.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'WEEKLY DISCIPLINE REPORT',
          style: AppTypography.titleSmall.copyWith(letterSpacing: 2.0),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary KPI Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: 'COMPLETION',
                      value: '$completionRate%',
                      sub: '$tasksCompleted / $tasksAttempted tasks',
                      color: AppColors.emeraldVictory,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'STREAK',
                      value: '$currentStreak Days',
                      sub: 'Best day: $bestDay',
                      color: AppColors.amberFocus,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: 'XP EARNED',
                      value: '+$xpEarned XP',
                      sub: 'Ledger verified',
                      color: AppColors.cyanDiscovery,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'DISCIPLINE SCORE',
                      value: '87 / 100',
                      sub: 'Rolling 30-day index',
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Tactical Behavioral Insight Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: const Color(0xFF15181E),
                  borderRadius: AppRadii.radiusLarge,
                  border:
                      Border.all(color: AppColors.amberFocus.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.lightbulb_outline,
                            color: AppColors.amberFocus, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'BEHAVIORAL INSIGHT',
                          style: TextStyle(
                              color: AppColors.amberFocus,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      insight,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              AppButton(
                label: 'CONTINUE DISCIPLINE ROUTINE',
                variant: AppButtonVariant.primary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF15181E),
        borderRadius: AppRadii.radiusMedium,
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
