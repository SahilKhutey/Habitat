// Reusable AppCard Component
import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';
import '../../tokens/radii.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final double borderWidth;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.borderColor,
    this.borderWidth = 1.0,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final border = borderColor ?? (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    Widget card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.radiusExtraLarge,
        border: Border.all(color: border, width: borderWidth),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadii.radiusExtraLarge,
        child: card,
      );
    }
    return card;
  }
}
