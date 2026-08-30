// Mission Success Celebration Screen
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class MissionSuccessScreen extends StatelessWidget {
  const MissionSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: AppSpacing.lg),

              // Celebration Centerpiece
              Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.emeraldVictory.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.emeraldVictory, width: 3),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.check, color: AppColors.emeraldVictory, size: 54),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text('MISSION ACCOMPLISHED', style: AppTypography.displayMedium),
                  const SizedBox(height: AppSpacing.xs),
                  const Text('Wake-up alarm disarmed. Proof verified.', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: AppSpacing.xxl),

                  // Reward Box
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppRadii.radiusLarge,
                      border: Border.all(color: AppColors.emeraldVictory),
                    ),
                    child: Column(
                      children: [
                        const Text('+45 XP DEPOSITED', style: TextStyle(color: AppColors.emeraldVictory, fontSize: 24, fontWeight: FontWeight.w900)),
                        const SizedBox(height: AppSpacing.xxs),
                        const Text('Includes +50% Instant Action Speed Bonus', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: const [
                                Text('CURRENT STREAK', style: AppTypography.labelSmall),
                                SizedBox(height: 4),
                                Text('🔥 13 Days', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: const [
                                Text('GRACE VAULT', style: AppTypography.labelSmall),
                                SizedBox(height: 4),
                                Text('🛡️ 1 Token', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Done Button
              AppButton.primary(
                label: 'RETURN TO DISCIPLINE DASHBOARD',
                icon: Icons.dashboard,
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
