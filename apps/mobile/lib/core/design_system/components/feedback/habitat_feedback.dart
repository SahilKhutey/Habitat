// Habitat Design System - Feedback & State Primitives
import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../../tokens/typography.dart';
import '../buttons/habitat_buttons.dart';

class HabitatEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const HabitatEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HabitatSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(HabitatSpacing.lg),
              decoration: BoxDecoration(
                color: HabitatColors.surfaceSecondary,
                shape: BoxShape.circle,
                border: Border.all(color: HabitatColors.surfaceBorder),
              ),
              child: Icon(icon, size: 40, color: HabitatColors.youngLeaf),
            ),
            const SizedBox(height: HabitatSpacing.lg),
            Text(
              title,
              style: const TextStyle(
                fontFamily: HabitatTypography.fontHeading,
                fontSize: HabitatTypography.title,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: HabitatSpacing.xs),
            Text(
              message,
              style: const TextStyle(
                fontFamily: HabitatTypography.fontBody,
                fontSize: HabitatTypography.body,
                color: HabitatColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: HabitatSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class HabitatErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const HabitatErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HabitatSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(HabitatSpacing.lg),
              decoration: BoxDecoration(
                color: HabitatColors.danger.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: HabitatColors.danger),
              ),
              child: const Icon(Icons.error_outline, size: 40, color: HabitatColors.danger),
            ),
            const SizedBox(height: HabitatSpacing.lg),
            Text(
              title,
              style: const TextStyle(
                fontFamily: HabitatTypography.fontHeading,
                fontSize: HabitatTypography.title,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: HabitatSpacing.xs),
            Text(
              message,
              style: const TextStyle(
                fontFamily: HabitatTypography.fontBody,
                fontSize: HabitatTypography.body,
                color: HabitatColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: HabitatSpacing.xl),
              HabitatSecondaryButton(
                label: 'Retry Action',
                icon: const Icon(Icons.replay, size: 16),
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void showHabitatSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: HabitatTypography.fontBody,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: isError ? HabitatColors.danger : HabitatColors.surfacePrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HabitatRadius.md)),
    ),
  );
}
