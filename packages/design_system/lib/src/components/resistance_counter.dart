// Animated Resistance Counter (ΔtR) Component
import 'package:flutter/material.dart';
import '../colors.dart';
import '../typography.dart';
import '../spacing.dart';

class ResistanceCounterWidget extends StatelessWidget {
  final int elapsedSeconds;
  final bool isEscalating;

  const ResistanceCounterWidget({
    super.key,
    required this.elapsedSeconds,
    this.isEscalating = false,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (elapsedSeconds % 60).toString().padLeft(2, '0');

    final color = elapsedSeconds <= 120
        ? HabitatColors.emeraldVictory
        : (elapsedSeconds <= 300 ? HabitatColors.amberFocus : HabitatColors.crimsonAlert);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: HabitatSpacing.l, vertical: HabitatSpacing.m),
      decoration: BoxDecoration(
        color: HabitatColors.surfacePrimary,
        borderRadius: HabitatRadii.radiusL,
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer, size: 16, color: color),
              const SizedBox(width: HabitatSpacing.xs),
              Text(
                'RESISTANCE (ΔtR)',
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: HabitatSpacing.xxs),
          Text(
            '$minutes:$seconds',
            style: HabitatTypography.monospaceCounter.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
