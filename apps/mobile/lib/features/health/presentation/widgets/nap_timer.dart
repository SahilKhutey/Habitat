// Habitat Nap Timer Display Widget
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';

class NapTimer extends StatelessWidget {
  final String formattedTime;
  final bool isRunning;

  const NapTimer({
    super.key,
    required this.formattedTime,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRunning
                  ? const Color(0xFF7209B7).withOpacity(0.15)
                  : HabitatTheme.surfaceSecondary,
              border: Border.all(
                color: isRunning ? const Color(0xFF7209B7) : HabitatTheme.surfaceBorder,
                width: isRunning ? 3 : 1,
              ),
            ),
            child: Icon(
              Icons.bedtime_outlined,
              size: 54,
              color: isRunning ? const Color(0xFF7209B7) : HabitatTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            formattedTime,
            style: TextStyle(
              fontFamily: HabitatTheme.fontHeading,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: isRunning ? Colors.white : HabitatTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isRunning ? 'Rest session actively recording...' : 'Ready for quiet recovery',
            style: const TextStyle(
              fontFamily: HabitatTheme.fontBody,
              fontSize: 13,
              color: HabitatTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
