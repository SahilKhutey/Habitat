// Proof Result Screen (Accepted vs Actionable Guidance for Rejection)
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class ProofResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const ProofResultScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    final isAccepted = resultData['isAccepted'] as bool? ?? false;
    final taskName = resultData['taskName'] as String? ?? 'Discipline Task';
    final reason = resultData['reason'] as String? ?? 'Proof did not meet verification criteria.';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Status Centerpiece
              Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: (isAccepted ? AppColors.emeraldVictory : AppColors.crimsonAlert).withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isAccepted ? AppColors.emeraldVictory : AppColors.crimsonAlert,
                        width: 3,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isAccepted ? Icons.check : Icons.close,
                      color: isAccepted ? AppColors.emeraldVictory : AppColors.crimsonAlert,
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    isAccepted ? 'PROOF ACCEPTED' : 'PROOF INSUFFICIENT',
                    style: AppTypography.displayMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isAccepted
                        ? '$taskName verified successfully.\nWake-up alarm stopped.'
                        : reason,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isAccepted ? Colors.white70 : AppColors.crimsonAlert,
                      fontSize: 14,
                    ),
                  ),
                  if (!isAccepted) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: AppRadii.radiusMedium,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        '💡 Your alarm retry will ring in 5 minutes unless completed.\nYou can recapture immediately.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),

              // Bottom Action Button
              AppButton.primary(
                label: isAccepted ? 'PROCEED TO REWARDS' : 'RECAPTURE PROOF NOW',
                icon: isAccepted ? Icons.arrow_forward : Icons.refresh,
                onPressed: () {
                  if (isAccepted) {
                    Navigator.of(context).pushReplacementNamed('/missions/success');
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
