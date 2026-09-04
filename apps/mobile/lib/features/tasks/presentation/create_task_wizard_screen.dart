// 5-Step Progressive Task Creation Wizard
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class CreateTaskWizardScreen extends StatefulWidget {
  const CreateTaskWizardScreen({super.key});

  @override
  State<CreateTaskWizardScreen> createState() => _CreateTaskWizardScreenState();
}

class _CreateTaskWizardScreenState extends State<CreateTaskWizardScreen> {
  int _step = 0; // 0: What, 1: Proof, 2: Difficulty, 3: Review
  final _nameController = TextEditingController(text: '10 Morning Push-Ups');
  String _proofType = 'VIDEO';
  int _difficulty = 2; // 1 to 5
  final int _baseXp = 30;

  int get _calculatedXp {
    const mults = {1: 1.0, 2: 1.25, 3: 1.5, 4: 2.0, 5: 2.5};
    return (_baseXp * (mults[_difficulty] ?? 1.0)).round();
  }

  void _nextStep() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      AppFeedback.showToast(context,
          message: 'Discipline Task Created & Ready for Alarm Scheduling!');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('CREATE TASK (STEP ${_step + 1}/4)'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Progress
              AppProgressBar(progress: (_step + 1) / 4.0),
              const SizedBox(height: AppSpacing.xxl),

              // Content based on step
              Expanded(
                child: _buildStepContent(),
              ),

              // Bottom Button
              AppButton.primary(
                label: _step == 3 ? 'CONFIRM & ACTIVATE TASK' : 'CONTINUE',
                onPressed: _nextStep,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('STEP 1: TASK IDENTITY',
                style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            const Text('What will you accomplish?',
                style: AppTypography.displayMedium),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Task Name',
              controller: _nameController,
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('STEP 2: PROOF REQUIREMENT',
                style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            const Text('How will you verify completion?',
                style: AppTypography.displayMedium),
            const SizedBox(height: AppSpacing.xl),
            _buildProofOption(
                'VIDEO', 'Video Recording (AI Pose Counter)', Icons.videocam),
            const SizedBox(height: AppSpacing.md),
            _buildProofOption('PHOTO',
                'Photo Check-in (AI Smart Object Detection)', Icons.camera_alt),
            const SizedBox(height: AppSpacing.md),
            _buildProofOption(
                'MANUAL', 'Manual Shutter Verification', Icons.touch_app),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('STEP 3: DIFFICULTY SCALE',
                style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            const Text('Set Resistance Level',
                style: AppTypography.displayMedium),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [1, 2, 3, 4, 5].map((lvl) {
                final isSelected = lvl == _difficulty;
                return InkWell(
                  onTap: () => setState(() => _difficulty = lvl),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.amberFocus
                          : AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$lvl',
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary,
                borderRadius: AppRadii.radiusLarge,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('SERVER XP REWARD:',
                      style: AppTypography.labelMedium),
                  Text('+$_calculatedXp XP',
                      style: const TextStyle(
                          color: AppColors.emeraldVictory,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        );
      case 3:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('STEP 4: REVIEW COMMITMENT',
                style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            const Text('Ready to Schedule', style: AppTypography.displayMedium),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_nameController.text,
                      style: AppTypography.displayMedium),
                  const SizedBox(height: AppSpacing.md),
                  Text('Proof: $_proofType • Difficulty Level: $_difficulty',
                      style: AppTypography.bodySmall),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Expected Reward: +$_calculatedXp XP',
                      style: const TextStyle(
                          color: AppColors.emeraldVictory,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildProofOption(String type, String title, IconData icon) {
    final isSelected = _proofType == type;
    return AppCard(
      borderColor: isSelected ? AppColors.amberFocus : AppColors.surfaceBorder,
      onTap: () => setState(() => _proofType = type),
      child: Row(
        children: [
          Icon(icon, color: isSelected ? AppColors.amberFocus : Colors.white70),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(title, style: AppTypography.titleMedium)),
          if (isSelected)
            const Icon(Icons.check_circle, color: AppColors.amberFocus),
        ],
      ),
    );
  }
}
