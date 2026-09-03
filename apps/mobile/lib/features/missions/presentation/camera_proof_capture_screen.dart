// Camera Proof Capture Viewport Screen
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import '../../../core/platform/media/native_camera_proof_pipeline.dart';

class CameraProofCaptureScreen extends StatefulWidget {
  final String? taskId;
  final String? attemptId;

  const CameraProofCaptureScreen({
    super.key,
    this.taskId,
    this.attemptId,
  });

  @override
  State<CameraProofCaptureScreen> createState() => _CameraProofCaptureScreenState();
}

class _CameraProofCaptureScreenState extends State<CameraProofCaptureScreen> {
  bool _isRecording = false;

  void _triggerCapture() {
    setState(() => _isRecording = true);
    final pipeline = NativeCameraProofPipeline();
    final taskId = widget.taskId ?? 'task-default';
    final attemptId = widget.attemptId ?? 'attempt-${DateTime.now().millisecondsSinceEpoch}';

    pipeline.captureVideoProof(
      taskId: taskId,
      attemptId: attemptId,
      durationSeconds: 5,
    ).then((proof) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/missions/verifying',
          arguments: {'taskId': taskId, 'attemptId': attemptId, 'proof': proof},
        );
      }
    }).catchError((err) {
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $err')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Viewfinder Viewport
          Center(
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.amberFocus.withOpacity(0.4), width: 2),
                borderRadius: AppRadii.radiusLarge,
              ),
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.crop_free, color: Colors.white24, size: 120),
                  SizedBox(height: AppSpacing.md),
                  Text('ALIGN TARGET IN FRAME', style: TextStyle(color: Colors.white54, letterSpacing: 2)),
                ],
              ),
            ),
          ),

          // Live Telemetry Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: AppRadii.radiusSmall,
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wb_sunny, color: AppColors.amberFocus, size: 16),
                        SizedBox(width: 4),
                        Text('85 LUX (GOOD)', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: AppRadii.radiusSmall,
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.sensors, color: AppColors.emeraldVictory, size: 16),
                        SizedBox(width: 4),
                        Text('MOTION SENSORS READY', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Shutter Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: InkWell(
                onTap: _triggerCapture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isRecording ? AppColors.crimsonAlert : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70, width: 4),
                  ),
                  alignment: Alignment.center,
                  child: _isRecording
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.circle, color: Colors.black, size: 40),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
