// Habitat Action Details Card Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/action_model.dart';

class ActionCard extends StatelessWidget {
  final TaskActionModel action;
  final VoidCallback? onSelect;
  final bool isSelected;

  const ActionCard({
    super.key,
    required this.action,
    this.onSelect,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? HabitatTheme.surfaceSecondary
            : HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? HabitatTheme.growthGreen
              : HabitatTheme.surfaceBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: HabitatTheme.habitatGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    action.type == ActionType.video
                        ? Icons.videocam_outlined
                        : Icons.camera_alt_outlined,
                    color: HabitatTheme.growthGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: const TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action.instruction,
                        style: const TextStyle(
                          fontFamily: HabitatTheme.fontBody,
                          fontSize: 12,
                          color: HabitatTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: HabitatTheme.surfaceSecondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          action.typeDisplayName,
                          style: const TextStyle(
                            fontFamily: HabitatTheme.fontHeading,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: HabitatTheme.youngLeaf,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: HabitatTheme.growthGreen, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
