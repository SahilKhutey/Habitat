// Habitat Dedicated Streak & Grace Vault Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../application/streak_controller.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/services/streak_service.dart';
import '../widgets/streak_card.dart';

class StreakPage extends StatefulWidget {
  final StreakController? controller;

  const StreakPage({super.key, this.controller});

  @override
  State<StreakPage> createState() => _StreakPageState();
}

class _StreakPageState extends State<StreakPage> {
  late final StreakController _controller;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      final db = LocalDatabase.instance;
      _controller = StreakController(
        streakService: StreakService(ProgressRepository(db)),
        database: db,
      );
      _internalController = true;
    }
  }

  @override
  void dispose() {
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleUseGraceToken() {
    final success = _controller.useGraceToken();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛡️ Grace Token consumed! Streak preserved.'),
          backgroundColor: HabitatTheme.surfacePrimary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No Grace Tokens remaining in your vault.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final streak = _controller.streak;

        return Scaffold(
          backgroundColor: HabitatTheme.background,
          appBar: AppBar(
            title: const Text('DISCIPLINE STREAK'),
            backgroundColor: HabitatTheme.background,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Streak Hero Card
                  StreakCard(streak: streak),
                  const SizedBox(height: 20),

                  // Grace Vault Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: HabitatTheme.surfacePrimary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: HabitatTheme.youngLeaf.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: HabitatTheme.youngLeaf, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'GRACE VAULT RECOVERY',
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
                        const SizedBox(height: 10),
                        Text(
                          '${streak.graceTokens} of 3 Protection Tokens Available',
                          style: const TextStyle(
                            fontFamily: HabitatTheme.fontHeading,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Grace tokens protect your streak on emergency missed days without fabricating completions. Earn 1 token every 14 days of consistency.',
                          style: TextStyle(
                            fontFamily: HabitatTheme.fontBody,
                            fontSize: 12,
                            color: HabitatTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        if (streak.graceTokens > 0) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _handleUseGraceToken,
                            icon: const Icon(Icons.shield, size: 16),
                            label: const Text('Consume Grace Token To Protect Streak'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: HabitatTheme.youngLeaf,
                              side: const BorderSide(color: HabitatTheme.youngLeaf),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Habitat Stage Evolution Journey
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: HabitatTheme.surfacePrimary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: HabitatTheme.surfaceBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HABITAT EVOLUTION STAGES',
                          style: TextStyle(
                            fontFamily: HabitatTheme.fontHeading,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: HabitatTheme.youngLeaf,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildStageRow('Sprout Stage', '1 - 2 Days', streak.currentStreak >= 1),
                        _buildStageRow('Sapling Stage', '3 - 6 Days', streak.currentStreak >= 3),
                        _buildStageRow('Canopy Stage', '7 - 20 Days', streak.currentStreak >= 7),
                        _buildStageRow('Ancient Forest', '21+ Days', streak.currentStreak >= 21),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStageRow(String stage, String days, bool isReached) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isReached ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: isReached ? HabitatTheme.growthGreen : HabitatTheme.textMuted,
              ),
              const SizedBox(width: 10),
              Text(
                stage,
                style: TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 13,
                  fontWeight: isReached ? FontWeight.w800 : FontWeight.w500,
                  color: isReached ? Colors.white : HabitatTheme.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            days,
            style: TextStyle(
              fontFamily: HabitatTheme.fontBody,
              fontSize: 12,
              color: isReached ? HabitatTheme.growthGreen : HabitatTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
