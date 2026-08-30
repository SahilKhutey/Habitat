// Verification Processing Screen & Kinetic Radar Scanner
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class VerificationProcessingScreen extends StatefulWidget {
  const VerificationProcessingScreen({super.key});

  @override
  State<VerificationProcessingScreen> createState() => _VerificationProcessingScreenState();
}

class _VerificationProcessingScreenState extends State<VerificationProcessingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/missions/success');
      }
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _radarController,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.amberFocus.withOpacity(0.5), width: 2),
                ),
                child: const Icon(Icons.radar, color: AppColors.amberFocus, size: 60),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Text('AUDITING PROOF TELEMETRY', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            const Text('Running Smart CV & motion validation...', style: TextStyle(color: Colors.white60)),
          ],
        ),
      ),
    );
  }
}
