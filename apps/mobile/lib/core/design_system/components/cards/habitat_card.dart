// Habitat Design System - Standardized Card Suite
import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../../tokens/typography.dart';

class HabitatCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const HabitatCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: borderColor ?? HabitatColors.surfaceBorder,
      width: 1,
    );

    final decoration = BoxDecoration(
      color: backgroundColor ?? HabitatColors.surfacePrimary,
      borderRadius: BorderRadius.circular(HabitatRadius.lg),
      border: border,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HabitatRadius.lg),
          child: Container(
            padding: padding ?? const EdgeInsets.all(HabitatSpacing.lg),
            decoration: decoration,
            child: child,
          ),
        ),
      );
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(HabitatSpacing.lg),
      decoration: decoration,
      child: child,
    );
  }
}

class HabitatSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const HabitatSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontFamily: HabitatTypography.fontHeading,
                fontSize: HabitatTypography.label,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: HabitatColors.youngLeaf,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: HabitatSpacing.xs),
        HabitatCard(child: child),
      ],
    );
  }
}
