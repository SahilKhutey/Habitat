// Tactical Active Mission HUD Screen
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../packages/design_system/lib/design_system.dart';

class ActiveMissionScreen extends StatefulWidget {
  final Map<String, dynamic> mission;

  const ActiveMissionScreen({super.key, required this.mission});

  @override
  State<ActiveMissionScreen> createState() => _ActiveMissionScreenState();
}

class _ActiveMissionScreenState extends State<ActiveMissionScreen> {
  int _secondsElapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isSpeedBonus = _secondsElapsed <= 120;
    final taskName = widget.mission['taskTitle'] as String? ?? '10 Morning Push-Ups';
    final proofType = widget.mission['taskProofType'] as String? ?? 'VIDEO';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const MissionStatusBadge(status: 'ACTIVE'),
                      if (isSpeedBonus)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.amberFocus.withOpacity(0.2),
                            borderRadius: AppRadii.radiusSmall,
                            border: Border.all(color: AppColors.amberFocus),
                          ),
                          child: const Text('⚡ +50% SPEED BONUS ACTIVE', style: TextStyle(color: AppColors.amberFocus, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(taskName, style: AppTypography.displayLarge.copyWith(color: Colors.white)),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('Proof Required: $proofType Evidence', style: const TextStyle(color: Colors.white70)),
                ],
              ),

              // Resistance Seconds Big Clock
              Center(
                child: Column(
                  children: [
                    const Text('RESISTANCE TIME (ΔtR)', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _formattedTime,
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: AppColors.amberFocus,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isSpeedBonus ? 'Finish in under 02:00 for Instant Action Bonus' : 'Standard XP Award Active',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Action Button
              Column(
                children: [
                  AppButton.primary(
                    label: 'CAPTURE PROOF ($proofType)',
                    icon: proofType == 'VIDEO' ? Icons.videocam : Icons.camera_alt,
                    onPressed: () {
                      Navigator.of(context).pushNamed('/missions/capture-proof', arguments: widget.mission);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
