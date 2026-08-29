// Tactical Active Mission HUD Screen
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../packages/design_system/lib/design_system.dart';

class ActiveMissionScreen extends StatefulWidget {
  final Map<String, dynamic>? mission;
  final String? missionId;
  final String? taskTitle;
  final String? missionType;
  final String? verificationType;

  const ActiveMissionScreen({
    super.key,
    this.mission,
    this.missionId,
    this.taskTitle,
    this.missionType,
    this.verificationType,
  });

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
    final taskName = widget.taskTitle ??
        (widget.mission != null ? widget.mission!['taskTitle'] as String? : null) ??
        '10 Morning Push-Ups';
    final proofType = widget.verificationType ??
        (widget.mission != null ? widget.mission!['taskProofType'] as String? : null) ??
        'VIDEO';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
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
                            color: AppColors.growthGreen.withOpacity(0.2),
                            borderRadius: AppRadii.radiusSmall,
                            border: Border.all(color: AppColors.growthGreen),
                          ),
                          child: const Text('⚡ +50% SPEED BONUS ACTIVE', style: TextStyle(color: AppColors.growthGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(taskName, style: AppTypography.displayLarge.copyWith(color: Colors.white)),
                  const SizedBox(height: AppSpacing.xs),
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
                        color: AppColors.growthGreen,
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
                      Navigator.of(context).pushNamed('/missions/capture-proof', arguments: widget.mission ?? {
                        'taskTitle': taskName,
                        'taskProofType': proofType,
                        'missionId': widget.missionId ?? 'active-mission',
                      });
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
