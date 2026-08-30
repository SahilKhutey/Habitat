// Health, Exercise & Wellness Dashboard Screen
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class HealthDashboardScreen extends StatelessWidget {
  final int todayMovementMinutes;
  final double currentWaterLiters;
  final double targetWaterLiters;
  final double sleepDurationHours;
  final int exerciseSessionsCount;
  final List<Map<String, dynamic>> wellnessGoals;

  const HealthDashboardScreen({
    super.key,
    this.todayMovementMinutes = 35,
    this.currentWaterLiters = 1.8,
    this.targetWaterLiters = 2.5,
    this.sleepDurationHours = 7.5,
    this.exerciseSessionsCount = 1,
    this.wellnessGoals = const [
      {'name': 'Move for 30 min', 'progress': 0.85, 'target': '30 min'},
      {'name': 'Drink 2.5L Water', 'progress': 0.72, 'target': '2.5 L'},
      {'name': 'Sleep 8 Hours', 'progress': 0.94, 'target': '8.0 h'}
    ],
  });

  @override
  Widget build(BuildContext context) {
    final waterProgress = (currentWaterLiters / targetWaterLiters).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'WELLNESS & HEALTH',
          style: AppTypography.titleSmall.copyWith(letterSpacing: 2.0),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Movement Card
              _buildMetricCard(
                icon: Icons.directions_run,
                iconColor: AppColors.amberFocus,
                title: "TODAY'S MOVEMENT",
                value: '$todayMovementMinutes min',
                subtitle: '$exerciseSessionsCount structured session completed',
              ),

              const SizedBox(height: AppSpacing.md),

              // Hydration Card with Quick Add
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: const Color(0xFF15181E),
                  borderRadius: AppRadii.radiusLarge,
                  border: Border.all(color: AppColors.cyanDiscovery.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.water_drop, color: AppColors.cyanDiscovery, size: 20),
                            SizedBox(width: 8),
                            Text('HYDRATION', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ],
                        ),
                        Text('${(waterProgress * 100).toInt()}%', style: const TextStyle(color: AppColors.cyanDiscovery, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${currentWaterLiters.toStringAsFixed(1)} / ${targetWaterLiters.toStringAsFixed(1)} L', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: AppRadii.radiusSmall,
                      child: LinearProgressIndicator(
                        value: waterProgress,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyanDiscovery),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildQuickAddButton('+250 ml'),
                        const SizedBox(width: 8),
                        _buildQuickAddButton('+500 ml'),
                        const SizedBox(width: 8),
                        _buildQuickAddButton('+750 ml'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Sleep Card
              _buildMetricCard(
                icon: Icons.bedtime,
                iconColor: const Color(0xFF9D4EDD),
                title: 'LAST NIGHT SLEEP',
                value: '${sleepDurationHours.toStringAsFixed(1)} h',
                subtitle: 'Target: 8.0 h (94% target adherence)',
              ),

              const SizedBox(height: AppSpacing.xl),

              // Active Goals Section
              Text('PERSONAL WELLNESS GOALS', style: AppTypography.titleSmall.copyWith(color: Colors.white70, letterSpacing: 1.5)),
              const SizedBox(height: AppSpacing.md),

              ...wellnessGoals.map((g) => Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15181E),
                      borderRadius: AppRadii.radiusMedium,
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(g['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('${((g['progress'] as double) * 100).toInt()}%', style: const TextStyle(color: AppColors.emeraldVictory, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: AppRadii.radiusSmall,
                          child: LinearProgressIndicator(
                            value: (g['progress'] as double).clamp(0.0, 1.0),
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emeraldVictory),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF15181E),
        borderRadius: AppRadii.radiusLarge,
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuickAddButton(String label) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white24),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusSmall),
        ),
        onPressed: () {},
        child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
