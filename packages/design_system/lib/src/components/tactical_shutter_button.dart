// Tactical Camera Shutter Component
import 'package:flutter/material.dart';
import '../colors.dart';

class TacticalShutterButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isVideo;
  final bool isRecording;

  const TacticalShutterButton({
    super.key,
    required this.onTap,
    this.isVideo = false,
    this.isRecording = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        padding: const EdgeInsets.all(6),
        child: Container(
          decoration: BoxDecoration(
            shape: isRecording ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isRecording ? BorderRadius.circular(8) : null,
            color: isVideo ? HabitatColors.crimsonAlert : HabitatColors.emeraldVictory,
          ),
        ),
      ),
    );
  }
}
