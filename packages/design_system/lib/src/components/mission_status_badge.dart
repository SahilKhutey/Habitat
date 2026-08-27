// Mission Status Badge Component
import 'package:flutter/material.dart';
import '../colors.dart';
import '../spacing.dart';

class MissionStatusBadge extends StatelessWidget {
  final String status; // 'SCHEDULED', 'ACTIVE', 'VERIFYING', 'COMPLETED', 'RETRYING'

  const MissionStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status.toUpperCase()) {
      case 'COMPLETED':
        bg = HabitatColors.emeraldVictorySubtle;
        fg = HabitatColors.emeraldVictory;
        icon = Icons.verified;
        break;
      case 'ACTIVE':
        bg = HabitatColors.amberFocusSubtle;
        fg = HabitatColors.amberFocus;
        icon = Icons.play_circle;
        break;
      case 'RETRYING':
        bg = HabitatColors.crimsonAlertSubtle;
        fg = HabitatColors.crimsonAlert;
        icon = Icons.alarm;
        break;
      case 'VERIFYING':
        bg = const Color(0xFF14202E);
        fg = HabitatColors.cyanTelemetry;
        icon = Icons.hourglass_top;
        break;
      default:
        bg = HabitatColors.surfaceSecondary;
        fg = HabitatColors.textSecondary;
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: HabitatSpacing.s, vertical: HabitatSpacing.xxs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: HabitatRadii.radiusS,
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: HabitatSpacing.xxs),
          Text(
            status.toUpperCase(),
            style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}
