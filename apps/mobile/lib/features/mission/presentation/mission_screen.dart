// Mission Execution HUD & State Machine View
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import '../domain/mission.dart';

class MissionScreen extends StatelessWidget {
  final MissionEntity mission;

  const MissionScreen({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('DISCIPLINE PROTOCOL'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header Status
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined,
                          color: AppColors.amberFocus, size: 20),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'SCHEDULED ${mission.scheduledAt.hour.toString().padLeft(2, '0')}:${mission.scheduledAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            color: AppColors.amberFocus,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    mission.status == MissionStatus.retry
                        ? 'RETRY PROTOCOL ACTIVE'
                        : (mission.status == MissionStatus.inProgress
                            ? 'MISSION IN PROGRESS'
                            : 'MISSION ACTIVE'),
                    style: AppTypography.displayMedium,
                  ),
                ],
              ),

              // Task Instructions Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppRadii.radiusLarge,
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  children: [
                    Icon(
                      mission.taskProofType == 'VIDEO'
                          ? Icons.videocam
                          : Icons.camera_alt,
                      color: AppColors.amberFocus,
                      size: 54,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      mission.taskTitle.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTypography.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      mission.taskInstructions,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Attempt ${mission.attemptCount + 1} • Retry Count: ${mission.retryCount}',
                      style: AppTypography.bodySmall,
                    ),
                    if (mission.status == MissionStatus.retry &&
                        mission.nextRetryAt != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.crimsonAlert.withOpacity(0.2),
                          borderRadius: AppRadii.radiusSmall,
                          border: Border.all(color: AppColors.crimsonAlert),
                        ),
                        child: const Text(
                          'Next Alarm in 5 minutes unless completed',
                          style: TextStyle(
                              color: AppColors.crimsonAlert,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Action Button
              AppButton.primary(
                label: mission.status == MissionStatus.inProgress
                    ? 'CAPTURE PROOF'
                    : 'START MISSION',
                icon: Icons.play_arrow,
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed('/missions/capture-proof', arguments: {
                    'missionId': mission.id,
                    'taskTitle': mission.taskTitle,
                    'proofType': mission.taskProofType,
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
