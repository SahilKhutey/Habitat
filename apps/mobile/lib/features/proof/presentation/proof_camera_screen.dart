// Tactical Proof Camera Screen with Dynamic Mission HUD & Task Instructions
import 'package:flutter/material.dart';
import '../../../../packages/design_system/lib/design_system.dart';
import '../domain/proof_type.dart';
import '../domain/capture_result.dart';
import '../data/proof_local_storage.dart';

class ProofCameraScreen extends StatefulWidget {
  final String missionId;
  final String attemptId;
  final String taskTitle;
  final String taskInstructions;
  final ProofType proofType;

  const ProofCameraScreen({
    super.key,
    required this.missionId,
    required this.attemptId,
    required this.taskTitle,
    required this.taskInstructions,
    required this.proofType,
  });

  @override
  State<ProofCameraScreen> createState() => _ProofCameraScreenState();
}

class _ProofCameraScreenState extends State<ProofCameraScreen> {
  bool _isRecording = false;
  int _secondsRecorded = 0;

  void _onCapture() async {
    final simulatedPath = '/local/app_data/proofs/${widget.missionId}_${widget.attemptId}.${widget.proofType == ProofType.video ? "mp4" : "jpg"}';
    final result = CaptureResult(
      localPath: simulatedPath,
      type: widget.proofType,
      sizeBytes: widget.proofType == ProofType.video ? 3500000 : 850000,
      duration: widget.proofType == ProofType.video ? Duration(seconds: _secondsRecorded > 0 ? _secondsRecorded : 12) : null,
      capturedAt: DateTime.now(),
    );

    // Save locally before upload
    await ProofLocalStorageService.saveProofLocally(
      missionId: widget.missionId,
      attemptId: widget.attemptId,
      result: result,
    );

    if (!mounted) return;
    Navigator.of(context).pushNamed('/proofs/preview', arguments: {
      'missionId': widget.missionId,
      'attemptId': widget.attemptId,
      'taskTitle': widget.taskTitle,
      'captureResult': result,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.proofType == ProofType.video;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Viewfinder Simulated Texture
            Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFF15181E),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isVideo ? Icons.videocam : Icons.camera_alt,
                        color: Colors.white24,
                        size: 96,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        '● CAMERA ACTIVE',
                        style: TextStyle(
                          color: AppColors.emeraldVictory,
                          letterSpacing: 2.0,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top HUD: Task Instructions
            Positioned(
              top: AppSpacing.lg,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: AppRadii.radiusLarge,
                  border: Border.all(color: AppColors.amberFocus.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.taskTitle.toUpperCase(), style: AppTypography.titleSmall),
                        if (_isRecording)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.crimsonAlert,
                              borderRadius: AppRadii.radiusSmall,
                            ),
                            child: Text(
                              '● REC 00:${_secondsRecorded.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.taskInstructions,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Shutter Controls
            Positioned(
              bottom: AppSpacing.xxl,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (isVideo) {
                        setState(() {
                          _isRecording = !_isRecording;
                          if (!_isRecording) _onCapture();
                        });
                      } else {
                        _onCapture();
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _isRecording ? AppColors.crimsonAlert : AppColors.amberFocus,
                      ),
                      child: Center(
                        child: Icon(
                          _isRecording ? Icons.stop : (isVideo ? Icons.videocam : Icons.camera),
                          color: Colors.black,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
