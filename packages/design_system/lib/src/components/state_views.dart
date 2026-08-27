// Reusable Empty, Loading, and Error State Components
import 'package:flutter/material.dart';
import '../colors.dart';
import '../typography.dart';
import '../spacing.dart';
import 'discipline_button.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox,
    this.actionLabel,
    this.onAction,
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
              padding: const EdgeInsets.all(HabitatSpacing.l),
              decoration: BoxDecoration(
                color: HabitatColors.surfaceSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: HabitatColors.textSecondary),
            ),
            const SizedBox(height: HabitatSpacing.l),
            Text(title, style: HabitatTypography.headline, textAlign: TextAlign.center),
            const SizedBox(height: HabitatSpacing.xs),
            Text(message, style: HabitatTypography.body, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: HabitatSpacing.xl),
              DisciplineButton(
                label: actionLabel!,
                onPressed: onAction!,
                variant: DisciplineButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingPulseWidget extends StatelessWidget {
  final String? message;

  const LoadingPulseWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: HabitatColors.amberFocus, strokeWidth: 3),
          if (message != null) ...[
            const SizedBox(height: HabitatSpacing.m),
            Text(message!, style: HabitatTypography.label),
          ],
        ],
      ),
    );
  }
}

class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String error;
  final VoidCallback onRetry;

  const ErrorStateWidget({
    super.key,
    this.title = 'MISSION ENGINE DISRUPTED',
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HabitatSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: HabitatColors.crimsonAlert),
            const SizedBox(height: HabitatSpacing.l),
            Text(title, style: HabitatTypography.headline.copyWith(color: HabitatColors.crimsonAlert)),
            const SizedBox(height: HabitatSpacing.xs),
            Text(error, style: HabitatTypography.body, textAlign: TextAlign.center),
            const SizedBox(height: HabitatSpacing.xl),
            DisciplineButton(
              label: 'RETRY PROTOCOL',
              onPressed: onRetry,
              variant: DisciplineButtonVariant.alert,
            ),
          ],
        ),
      ),
    );
  }
}
