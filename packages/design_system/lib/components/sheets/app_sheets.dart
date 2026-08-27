// Reusable AppBottomSheet Component
import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';
import '../../tokens/radii.dart';

class AppBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const AppBottomSheet({
    super.key,
    required this.title,
    required this.child,
  });

  static Future<T?> show<T>(BuildContext context, {required String title, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.extraLarge)),
      ),
      builder: (ctx) => AppBottomSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: AppRadii.radiusPill,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}
