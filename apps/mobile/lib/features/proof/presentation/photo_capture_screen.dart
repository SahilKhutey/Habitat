// Photo Proof Capture Screen
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import '../data/camera_service.dart';

class PhotoCaptureScreen extends StatefulWidget {
  final String missionId;
  final String taskName;

  const PhotoCaptureScreen({
    super.key,
    required this.missionId,
    required this.taskName,
  });

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  final CameraService _cameraService = CameraService();
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _cameraService.initialize();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    setState(() => _isCapturing = true);
    final result = await _cameraService.takePhoto(
        taskId: widget.missionId, attemptId: widget.missionId);
    final path = result.filePath;
    setState(() => _isCapturing = false);

    if (mounted) {
      Navigator.of(context).pushNamed(
        '/proof/preview',
        arguments: {
          'missionId': widget.missionId,
          'taskName': widget.taskName,
          'proofType': 'PHOTO',
          'filePath': path,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    color: AppColors.amberFocus.withOpacity(0.5), width: 2),
                borderRadius: AppRadii.radiusLarge,
              ),
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      color: Colors.white24, size: 80),
                  SizedBox(height: AppSpacing.md),
                  Text('FRAME PROOF CLEARLY',
                      style:
                          TextStyle(color: Colors.white54, letterSpacing: 2)),
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
                onTap: _isCapturing ? null : _takePhoto,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70, width: 4),
                  ),
                  alignment: Alignment.center,
                  child: _isCapturing
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Icon(Icons.circle, color: Colors.black, size: 36),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
