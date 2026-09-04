// Habitat Design System - Standardized Dialogs
import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/typography.dart';

Future<bool?> showHabitatConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: HabitatColors.surfacePrimary,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabitatRadius.lg)),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: HabitatTypography.fontHeading,
          fontSize: HabitatTypography.subtitle,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: HabitatTypography.fontBody,
          fontSize: HabitatTypography.body,
          color: HabitatColors.textSecondary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel,
              style: const TextStyle(color: HabitatColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: HabitatColors.growthGreen,
            foregroundColor: HabitatColors.forest,
          ),
          child: Text(confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

Future<bool?> showHabitatDestructiveDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: HabitatColors.surfacePrimary,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabitatRadius.lg)),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: HabitatTypography.fontHeading,
          fontSize: HabitatTypography.subtitle,
          fontWeight: FontWeight.w800,
          color: HabitatColors.danger,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: HabitatTypography.fontBody,
          fontSize: HabitatTypography.body,
          color: HabitatColors.textSecondary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel,
              style: const TextStyle(color: HabitatColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: HabitatColors.danger,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
