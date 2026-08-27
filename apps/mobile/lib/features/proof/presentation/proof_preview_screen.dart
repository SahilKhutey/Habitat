// Proof Preview & Submission Screen (Retake vs Submit)
import 'package:flutter/material.dart';
import '../../../../packages/design_system/lib/design_system.dart';

class ProofPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> proofData;

  const ProofPreviewScreen({super.key, required this.proofData});

  @override
  State<ProofPreviewScreen> createState() => _ProofPreviewScreenState();
}

class _ProofPreviewScreenState extends State<ProofPreviewScreen> {
  bool _isSubmitting = false;

  void _submitProof() {
    setState(() => _isSubmitting = true);

    // Simulate upload and verification pipeline
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final duration = widget.proofData['durationSeconds'] as int? ?? 12;
        final minDuration = widget.proofData['minDurationSeconds'] as int? ?? 10;

        if (duration < minDuration) {
          Navigator.of(context).pushReplacementNamed(
            '/proof/result',
            arguments: {
              'isAccepted': false,
              'reason': 'Video needs to be at least $minDuration seconds.',
              'missionId': widget.proofData['missionId'],
            },
          );
        } else {
          Navigator.of(context).pushReplacementNamed(
            '/proof/result',
            arguments: {
              'isAccepted': true,
              'taskName': widget.proofData['taskName'],
              'missionId': widget.proofData['missionId'],
            },
          );
        }
      }
    });
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
