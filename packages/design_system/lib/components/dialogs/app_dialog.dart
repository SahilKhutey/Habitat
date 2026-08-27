// Reusable AppDialog & ConfirmationDialog Components
import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';
import '../../tokens/radii.dart';
import '../buttons/app_button.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String? cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmLabel,
    this.cancelLabel = 'CANCEL',
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
    String cancelLabel = 'CANCEL',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.radiusExtraLarge),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.crimsonAlert : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Text(
        content,
        style: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          fontSize: 14,
          height: 1.4,
        ),
      ),
      actions: [
        if (cancelLabel != null)
          TextButton(
            onPressed: onCancel ?? () => Navigator.of(context).pop(),
            child: Text(
              cancelLabel!,
              style: TextStyle(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? AppColors.crimsonAlert : AppColors.amberFocus,
            foregroundColor: isDestructive ? Colors.white : Colors.black,
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.radiusMedium),
          ),
          onPressed: onConfirm,
          child: Text(
            confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
          ),
        ),
      ],
    );
  }
}
