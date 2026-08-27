// Proof Capture Viewfinder with Sensor Telemetry
import 'package:flutter/material.dart';
import '../../../core/theme/habitat_theme.dart';

class ProofCaptureView extends StatefulWidget {
  final String taskId;
  final String taskCategory;
  final String proofType;
  final int minLuminance;
  final Function(String localPath, Map<String, dynamic> telemetry)? onProofCaptured;

  const ProofCaptureView({
    super.key,
    required this.taskId,
    required this.taskCategory,
    this.proofType = 'PHOTO',
    this.minLuminance = 30,
    this.onProofCaptured,
  });

  @override
  State<ProofCaptureView> createState() => _ProofCaptureViewState();
}

class _ProofCaptureViewState extends State<ProofCaptureView> {
  double _currentLux = 65.0; // Simulated ambient sensor reading
  bool _motionDetected = true;
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    final isDark = _currentLux < widget.minLuminance;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Viewfinder Overlay
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 70),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? HabitatTheme.crimsonAlert : HabitatTheme.amberFocus,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Framing Silhouette Guide
                  Center(
                    child: Icon(
                      widget.taskCategory == 'physical' ? Icons.accessibility_new : Icons.crop_free,
                      size: 100,
                      color: isDark ? Colors.red.withOpacity(0.5) : Colors.white24,
                    ),
                  ),

                  // Sensor Telemetry HUD
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? Colors.red : Colors.green),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lightbulb, size: 14, color: isDark ? Colors.red : Colors.green),
                          const SizedBox(width: 6),
                          Text(
                            '${_currentLux.toInt()} LUX ${isDark ? "(TOO DARK)" : "(GOOD LIGHT)"}',
                            style: TextStyle(
                              color: isDark ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Bottom Shutter Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDark)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: HabitatTheme.crimsonAlert.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '⚠️ Turn on room lights to capture proof',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),

                GestureDetector(
                  onTap: isDark ? null : _handleCapture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? Colors.grey : Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey : HabitatTheme.amberFocus,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.proofType == 'VIDEO' ? Icons.videocam : Icons.camera,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleCapture() {
    final simulatedPath = '/app_storage/proofs/proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final telemetry = {
      'ambientLux': _currentLux,
      'accelerometerMotion': _motionDetected,
      'capturedAt': DateTime.now().toIso8601String(),
    };

    widget.onProofCaptured?.call(simulatedPath, telemetry);
  }
}
