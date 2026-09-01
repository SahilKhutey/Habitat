// Proof Preview & Submission Screen (Retake vs Submit)
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import '../../tasks/domain/models/action_model.dart';
import '../../tasks/domain/services/verification_service.dart';

class ProofPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> proofData;
  final VerificationService? verificationService;

  const ProofPreviewScreen({
    super.key,
    required this.proofData,
    this.verificationService,
  });

  @override
  State<ProofPreviewScreen> createState() => _ProofPreviewScreenState();
}

class _ProofPreviewScreenState extends State<ProofPreviewScreen> {
  late final VerificationService _verificationService;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _verificationService = widget.verificationService ?? VerificationService();
  }

  Future<void> _submitProof() async {
    setState(() => _isSubmitting = true);

    final isVideo = widget.proofData['proofType'] == 'VIDEO';
    final duration = widget.proofData['durationSeconds'] as int? ?? (isVideo ? 12 : 0);
    final taskId = widget.proofData['taskId'] as String? ?? 'task-1';
    final missionId = widget.proofData['missionId'] as String? ?? taskId;
    final proofPath = widget.proofData['proofPath'] as String? ?? 'proof.jpg';

    final result = await _verificationService.verifyProof(
      taskId: taskId,
      missionId: missionId,
      verificationType: isVideo ? VerificationType.videoProof : VerificationType.photoProof,
      proofPath: proofPath,
      durationSeconds: duration,
    );

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        '/proof/result',
        arguments: {
          'isAccepted': result.isSuccess,
          'reason': result.isSuccess ? null : result.message,
          'taskName': widget.proofData['taskName'] ?? 'Discipline Task',
          'missionId': missionId,
          'repsVerified': result.repsVerified,
          'isOffline': result.isOfflineFallback,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final proofType = widget.proofData['proofType'] as String? ?? 'PHOTO';
    final taskName = widget.proofData['taskName'] as String? ?? 'Discipline Task';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('REVIEW PROOF'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Preview Box
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppRadii.radiusLarge,
                    border: Border.all(color: Colors.white24),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        proofType == 'VIDEO' ? Icons.play_circle_fill : Icons.image,
                        color: AppColors.amberFocus,
                        size: 72,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(taskName, style: AppTypography.titleLarge),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        proofType == 'VIDEO'
                            ? '${widget.proofData['durationSeconds'] ?? 12}s Recorded • Ready to Verify'
                            : 'Well-lit Photo • Ready to Verify',
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Action Buttons (Retake vs Submit)
              _isSubmitting
                  ? Column(
                      children: const [
                        CircularProgressIndicator(color: AppColors.amberFocus),
                        SizedBox(height: AppSpacing.md),
                        Text('Uploading securely and auditing telemetry...', style: TextStyle(color: Colors.white70)),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: AppButton.outline(
                            label: 'RETAKE',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppButton.primary(
                            label: 'SUBMIT PROOF',
                            onPressed: _submitProof,
                          ),
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
