// Tactical Verification & Truth Scanning HUD with Dynamic Feedback
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class VerificationEvaluationScreen extends StatefulWidget {
  final String missionId;
  final String taskTitle;
  final String strategyUsed;
  final bool isVerifying;
  final bool? isValid;
  final double confidenceScore;
  final String? rejectionReason;
  final String? actionableAdvice;
  final Map<String, dynamic> extractedMetrics;

  const VerificationEvaluationScreen({
    super.key,
    required this.missionId,
    required this.taskTitle,
    this.strategyUsed = 'OBJECT_DETECTION_CV',
    this.isVerifying = false,
    this.isValid,
    this.confidenceScore = 0.94,
    this.rejectionReason,
    this.actionableAdvice,
    this.extractedMetrics = const {},
  });

  @override
  State<VerificationEvaluationScreen> createState() => _VerificationEvaluationScreenState();
}

class _VerificationEvaluationScreenState extends State<VerificationEvaluationScreen> {
  @override
  Widget build(BuildContext context) {
    final passed = widget.isValid == true;
    final failed = widget.isValid == false;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'TRUTH VERIFICATION',
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
              // Target Task Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFF15181E),
                  borderRadius: AppRadii.radiusMedium,
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: AppColors.amberFocus, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EVALUATING MISSION', style: AppTypography.labelSmall.copyWith(color: Colors.white54)),
                          Text(widget.taskTitle, style: AppTypography.titleSmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Scanning / Confidence Radar Viewport
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF15181E),
                    borderRadius: AppRadii.radiusLarge,
                    border: Border.all(
                      color: passed
                          ? AppColors.emeraldVictory
                          : (failed ? AppColors.crimsonAlert : AppColors.amberFocus.withOpacity(0.4)),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isVerifying) ...[
                          const SizedBox(
                            width: 64,
                            height: 64,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.amberFocus),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const Text(
                            'ANALYZING EVIDENCE...',
                            style: TextStyle(
                              color: AppColors.amberFocus,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ] else if (passed) ...[
                          const Icon(Icons.check_circle, color: AppColors.emeraldVictory, size: 80),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'PROOF VERIFIED',
                            style: TextStyle(
                              color: AppColors.emeraldVictory,
                              fontSize: 20,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Confidence: ${(widget.confidenceScore * 100).toInt()}% • Strategy: ${widget.strategyUsed}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ] else if (failed) ...[
                          const Icon(Icons.error_outline, color: AppColors.crimsonAlert, size: 80),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'VERIFICATION REJECTED',
                            style: TextStyle(
                              color: AppColors.crimsonAlert,
                              fontSize: 20,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: Text(
                              widget.rejectionReason ?? 'Proof did not meet task truth criteria.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                          if (widget.actionableAdvice != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: AppRadii.radiusSmall,
                              ),
                              child: Text(
                                '💡 ${widget.actionableAdvice}',
                                style: const TextStyle(color: AppColors.amberFocus, fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Action Buttons
              if (passed)
                AppButton(
                  label: 'CLAIM XP & COMPLETE',
                  variant: AppButtonVariant.primary,
                  onPressed: () => Navigator.of(context).pop(true),
                )
              else if (failed)
                AppButton(
                  label: 'RETRY CAPTURE',
                  variant: AppButtonVariant.critical,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
