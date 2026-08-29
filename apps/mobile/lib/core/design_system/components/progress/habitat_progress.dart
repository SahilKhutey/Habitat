// Habitat Design System - Progress Indicators & Stat Blocks
import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/typography.dart';

class HabitatProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color? color;
  final Color? backgroundColor;

  const HabitatProgressBar({
    super.key,
    required this.value,
    this.height = 8.0,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(HabitatRadius.xs),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: backgroundColor ?? HabitatColors.surfaceSecondary,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? HabitatColors.growthGreen),
      ),
    );
  }
}

class HabitatProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Widget? child;
  final Color? color;

  const HabitatProgressRing({
    super.key,
    required this.value,
    this.size = 80.0,
    this.strokeWidth = 6.0,
    this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value.clamp(0.0, 1.0),
            strokeWidth: strokeWidth,
            backgroundColor: HabitatColors.surfaceSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(color ?? HabitatColors.growthGreen),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class HabitatStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const HabitatStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? HabitatColors.growthGreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: effectiveColor),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: HabitatTypography.fontHeading,
                fontSize: HabitatTypography.caption,
                fontWeight: FontWeight.bold,
                color: HabitatColors.textMuted,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: HabitatTypography.fontHeading,
            fontSize: HabitatTypography.title,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
