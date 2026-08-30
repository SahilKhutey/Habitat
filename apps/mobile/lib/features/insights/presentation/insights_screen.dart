// Discipline Insights & Behavioral Analytics Screen
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class InsightsScreen extends StatelessWidget {
  final double overallCompletionRate;
  final String strongestHabit;
  final String bestTimeWindow;
  final String growingHabit;
  final String? needsAttention;
  final List<Map<String, dynamic>> recommendations;

  const InsightsScreen({
    super.key,
    this.overallCompletionRate = 88.5,
    this.strongestHabit = 'Morning Brushing (14-day consistency)',
    this.bestTimeWindow = '07:00–08:00',
    this.growingHabit = '10 Push-Ups Video',
    this.needsAttention = 'Evening Reset Protocol',
    this.recommendations = const [
      {
        'id': 'rec-1',
        'type': 'MOVE_TASK',
        'title': 'Optimize Exercise Timing',
        'explanation': 'You complete exercise 91% of the time between 07:00–08:00 vs 62% in the evening.',
        'confidence': 0.88,
        'action': 'Move to 07:30'
      },
      {
        'id': 'rec-2',
        'type': 'INCREASE_DIFFICULTY',
        'title': 'Advance Push-Up Challenge',
        'explanation': 'You have completed 10 pushups for 14 consecutive days with minimal resistance.',
        'confidence': 0.86,
        'action': 'Try 12–15 Reps'
      }
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'DISCIPLINE INSIGHTS',
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
              // Summary Banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B2230), Color(0xFF15181E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadii.radiusLarge,
                  border: Border.all(color: AppColors.cyanDiscovery.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OVERALL DISCIPLINE HEALTH', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${overallCompletionRate.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldVictory.withOpacity(0.2),
                            borderRadius: AppRadii.radiusSmall,
                          ),
                          child: const Text('STRONG MOMENTUM', style: TextStyle(color: AppColors.emeraldVictory, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Core Insights Grid
              _buildInsightCard('🔥 Strongest Habit', strongestHabit, AppColors.amberFocus),
              const SizedBox(height: AppSpacing.md),
              _buildInsightCard('⏰ Best Time Window', bestTimeWindow, AppColors.cyanDiscovery),
              const SizedBox(height: AppSpacing.md),
              _buildInsightCard('⚡ Growing Habit', growingHabit, AppColors.emeraldVictory),
              if (needsAttention != null) ...[
                const SizedBox(height: AppSpacing.md),
                _buildInsightCard('⚠️ Needs Attention', needsAttention!, AppColors.crimsonAlert),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Personalized Recommendations Section
              Text('PERSONALIZED RECOMMENDATIONS', style: AppTypography.titleSmall.copyWith(color: Colors.white70, letterSpacing: 1.5)),
              const SizedBox(height: AppSpacing.md),

              ...recommendations.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(r['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('${((r['confidence'] as double) * 100).toInt()}% match', style: const TextStyle(color: AppColors.cyanDiscovery, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(r['explanation'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.amberFocus,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onPressed: () {},
                              child: Text(r['action'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Keep Current', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            ),
                          ],
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

  Widget _buildInsightCard(String title, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF15181E),
        borderRadius: AppRadii.radiusLarge,
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
