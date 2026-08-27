// Video Proof Capture Screen with Minimum Duration Enforcer
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../packages/design_system/lib/design_system.dart';
import '../data/camera_service.dart';

class VideoCaptureScreen extends StatefulWidget {
  final String missionId;
  final String taskName;
  final int minDurationSeconds;

  const VideoCaptureScreen({
    super.key,
    required this.missionId,
    required this.taskName,
    this.minDurationSeconds = 10,
  });

  @override
  State<VideoCaptureScreen> createState() => _VideoCaptureScreenState();
}

class _VideoCaptureScreenState extends State<VideoCaptureScreen> {
  final CameraService _cameraService = CameraService();
  bool _isRecording = false;
  int _secondsRecorded = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cameraService.initialize(preferredCamera: 'FRONT');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraService.dispose();
    super.dispose();
  }

  void _toggleRecording() async {
    if (!_isRecording) {
      await _cameraService.startRecording();
      setState(() {
        _isRecording = true;
        _secondsRecorded = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _secondsRecorded++);
        }
      });
    } else {
      _timer?.cancel();
      final path = await _cameraService.stopRecording();
      setState(() => _isRecording = false);

      if (mounted) {
        Navigator.of(context).pushNamed(
          '/proof/preview',
          arguments: {
            'missionId': widget.missionId,
            'taskName': widget.taskName,
            'proofType': 'VIDEO',
            'filePath': path,
            'durationSeconds': _secondsRecorded,
            'minDurationSeconds': widget.minDurationSeconds,
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canStop = _secondsRecorded >= widget.minDurationSeconds;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.taskName.toUpperCase()),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _cameraService.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Viewfinder
          Center(
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isRecording ? AppColors.crimsonAlert : AppColors.amberFocus.withOpacity(0.5),
                  width: 2,
                ),
                borderRadius: AppRadii.radiusLarge,
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isRecording ? Icons.videocam : Icons.videocam_outlined,
                    color: _isRecording ? AppColors.crimsonAlert : Colors.white24,
                    size: 80,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _isRecording ? 'RECORDING EXERCISE REPS' : 'ALIGN FULL BODY IN FRAME',
                    style: TextStyle(
                      color: _isRecording ? AppColors.crimsonAlert : Colors.white54,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Duration Timer Banner
          if (_isRecording)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.crimsonAlert.withOpacity(0.8),
                    borderRadius: AppRadii.radiusMedium,
                  ),
                  child: Text(
                    '00:${_secondsRecorded.toString().padLeft(2, '0')} / 00:${widget.minDurationSeconds.toString().padLeft(2, '0')} MIN',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                ),
              ),
            ),

          // Record / Stop Shutter Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  if (_isRecording && !canStop)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        'Record at least ${widget.minDurationSeconds - _secondsRecorded}s more',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  InkWell(
                    onTap: _toggleRecording,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: _isRecording ? AppColors.crimsonAlert : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 4),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.circle,
                        color: _isRecording ? Colors.white : AppColors.crimsonAlert,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
