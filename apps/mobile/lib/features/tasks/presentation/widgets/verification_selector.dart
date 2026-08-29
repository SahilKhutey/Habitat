// Habitat Verification Selector Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/action_model.dart';

class VerificationSelector extends StatelessWidget {
  final ActionType selectedActionType;
  final VerificationType selectedVerificationType;
  final ValueChanged<ActionType> onActionTypeChanged;
  final ValueChanged<VerificationType> onVerificationTypeChanged;

  const VerificationSelector({
    super.key,
    required this.selectedActionType,
    required this.selectedVerificationType,
    required this.onActionTypeChanged,
    required this.onVerificationTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOption(
          type: ActionType.photo,
          verificationType: VerificationType.photoProof,
          title: 'Photo Verification Check-in',
          description: 'Capture a photo evidence of your finished discipline.',
          icon: Icons.camera_alt_outlined,
        ),
        const SizedBox(height: 10),
        _buildOption(
          type: ActionType.video,
          verificationType: VerificationType.videoProof,
          title: 'Video AI Pose Validation',
          description: 'Record repetitions with automated MoveNet pose estimation.',
          icon: Icons.videocam_outlined,
        ),
        const SizedBox(height: 10),
        _buildOption(
          type: ActionType.timer,
          verificationType: VerificationType.timerElapsed,
          title: 'Timed Resistance Session',
          description: 'Focus timer adherence (e.g. 5 min stretch / reading).',
          icon: Icons.timer_outlined,
        ),
        const SizedBox(height: 10),
        _buildOption(
          type: ActionType.confirmation,
          verificationType: VerificationType.manualConfirm,
          title: 'Manual Commitment Check-in',
          description: 'Simple one-tap verified confirmation upon completing action.',
          icon: Icons.touch_app_outlined,
        ),
      ],
    );
  }

  Widget _buildOption({
    required ActionType type,
    required VerificationType verificationType,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = selectedActionType == type;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? HabitatTheme.surfaceSecondary : HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? HabitatTheme.growthGreen : HabitatTheme.surfaceBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            onActionTypeChanged(type);
            onVerificationTypeChanged(verificationType);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? HabitatTheme.habitatGreen : HabitatTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: isSelected ? HabitatTheme.growthGreen : HabitatTheme.textSecondary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          fontFamily: HabitatTheme.fontBody,
                          fontSize: 12,
                          color: HabitatTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: HabitatTheme.growthGreen, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
