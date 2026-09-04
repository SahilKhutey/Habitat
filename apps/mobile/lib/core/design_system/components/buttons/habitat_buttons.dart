// Habitat Design System - Standardized Button Suite
import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../../tokens/typography.dart';

class HabitatPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final double? width;

  const HabitatPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      height: 50,
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: HabitatColors.growthGreen,
          foregroundColor: HabitatColors.forest,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HabitatRadius.md)),
          padding: const EdgeInsets.symmetric(horizontal: HabitatSpacing.lg),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: HabitatColors.forest),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: HabitatSpacing.xs)
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: HabitatTypography.fontHeading,
                      fontSize: HabitatTypography.body,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );

    return Semantics(button: true, label: label, child: child);
  }
}

class HabitatSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final double? width;

  const HabitatSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: width,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: HabitatColors.youngLeaf,
          side: const BorderSide(color: HabitatColors.youngLeaf),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HabitatRadius.md)),
          padding: const EdgeInsets.symmetric(horizontal: HabitatSpacing.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: HabitatSpacing.xs)
            ],
            Text(
              label,
              style: const TextStyle(
                fontFamily: HabitatTypography.fontHeading,
                fontSize: HabitatTypography.bodySmall,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HabitatDestructiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  const HabitatDestructiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: HabitatColors.danger,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HabitatRadius.md)),
          padding: const EdgeInsets.symmetric(horizontal: HabitatSpacing.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: HabitatSpacing.xs)
            ],
            Text(
              label,
              style: const TextStyle(
                fontFamily: HabitatTypography.fontHeading,
                fontSize: HabitatTypography.bodySmall,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HabitatIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? color;

  const HabitatIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: color ?? HabitatColors.growthGreen),
    );
  }
}
