// Habitat Permission Diagnostic Tile Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/permission_status.dart';

class PermissionTile extends StatelessWidget {
  final PermissionItemModel item;
  final VoidCallback? onRequest;

  const PermissionTile({
    super.key,
    required this.item,
    this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final isGranted = item.status == PermissionState.granted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? HabitatTheme.growthGreen.withOpacity(0.3)
              : HabitatTheme.surfaceBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _resolveIcon(item.type),
            color: isGranted ? HabitatTheme.growthGreen : HabitatTheme.textMuted,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.displayName,
                      style: const TextStyle(
                        fontFamily: HabitatTheme.fontHeading,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isGranted
                            ? HabitatTheme.growthGreen.withOpacity(0.2)
                            : Colors.redAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isGranted ? 'GRANTED' : 'DENIED',
                        style: TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isGranted ? HabitatTheme.growthGreen : Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.usageDescription,
                  style: const TextStyle(
                    fontFamily: HabitatTheme.fontBody,
                    fontSize: 12,
                    color: HabitatTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _resolveIcon(PermissionType type) => switch (type) {
        PermissionType.notifications => Icons.notifications_active_outlined,
        PermissionType.exactAlarms => Icons.alarm_on_outlined,
        PermissionType.camera => Icons.camera_alt_outlined,
        PermissionType.microphone => Icons.mic_none_outlined,
        PermissionType.location => Icons.location_on_outlined,
      };
}
