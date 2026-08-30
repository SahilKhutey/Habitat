// Habitat Proof Camera HUD Screen
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/colors.dart';
import '../../../core/design_system/tokens/radii.dart';
import '../../../core/design_system/tokens/spacing.dart';
import '../data/camera_service.dart';
import '../domain/capture_result.dart';

class ProofCameraScreen extends StatefulWidget {
  final String taskId;
  final String attemptId;
  final bool isVideoRequired;

  const ProofCameraScreen({
    super.key,
    required this.taskId,
    required this.attemptId,
    this.isVideoRequired = false,
  });

  @override
  State<ProofCameraScreen> createState() => _ProofCameraScreenState();
}

class _ProofCameraScreenState extends State<ProofCameraScreen> {
  final CameraService _cameraService = CameraService();
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cameraService.initialize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraService.dispose();
    super.dispose();
  }

  void _toggleRecordingTimer(bool start) {
    if (start) {
      _recordingSeconds = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });
      });
    } else {
      _timer?.cancel();
    }
  }

  Future<void> _handleCapture() async {
    setState(() => _errorMessage = null);

    if (widget.isVideoRequired) {
      if (!_isRecording) {
        // Start Video Recording
        await _cameraService.startVideoRecording();
        setState(() => _isRecording = true);
        _toggleRecordingTimer(true);
      } else {
        // Stop Video Recording
        _toggleRecordingTimer(false);
        final capture = await _cameraService.stopVideoRecording(
          taskId: widget.taskId,
          attemptId: widget.attemptId,
        );
        setState(() => _isRecording = false);

        if (capture.durationSeconds < 3) {
          setState(() {
            _errorMessage = 'Recording too short. Video must be at least 3 seconds (was ${_recordingSeconds}s).';
          });
          return;
        }

        if (mounted) {
          Navigator.of(context).pop(capture);
        }
      }
    } else {
      // Photo Capture
      final capture = await _cameraService.takePhoto(
        taskId: widget.taskId,
        attemptId: widget.attemptId,
      );
      if (mounted) {
        Navigator.of(context).pop(capture);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Viewfinder Surface
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Icon(
                    widget.isVideoRequired ? Icons.videocam : Icons.camera_alt,
                    size: 140,
                    color: HabitatColors.youngLeaf.withOpacity(0.2),
                  ),
                ),
              ),
            ),

            // Top Header Bar
            Positioned(
              top: HabitatSpacing.md,
              left: HabitatSpacing.md,
              right: HabitatSpacing.md,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  if (_isRecording)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: HabitatColors.crimsonAlert,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.fiber_manual_record, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '${_recordingSeconds ~/ 60}:${(_recordingSeconds % 60).toString().padLeft(2, "0")}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 28),
                    onPressed: () => _cameraService.switchCamera(),
                  ),
                ],
              ),
            ),

            // Error Banner
            if (_errorMessage != null)
              Positioned(
                bottom: 120,
                left: HabitatSpacing.lg,
                right: HabitatSpacing.lg,
                child: Container(
                  padding: const EdgeInsets.all(HabitatSpacing.md),
                  decoration: BoxDecoration(
                    color: HabitatColors.crimsonAlert.withOpacity(0.95),
                    borderRadius: HabitatRadius.radiusCard,
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Bottom Shutter Controls
            Positioned(
              bottom: HabitatSpacing.xl,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _handleCapture,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _isRecording
                          ? HabitatColors.crimsonAlert
                          : HabitatColors.growthGreen,
                    ),
                    child: Center(
                      child: Icon(
                        _isRecording
                            ? Icons.stop
                            : (widget.isVideoRequired ? Icons.fiber_manual_record : Icons.camera),
                        color: _isRecording ? Colors.white : HabitatColors.forest,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
