// Tactical Card Container Component
import 'package:flutter/material.dart';
import '../colors.dart';
import '../spacing.dart';

class TacticalCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final double borderWidth;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const TacticalCard({
    super.key,
    required this.child,
    this.borderColor,
    this.borderWidth = 1.0,
    this.backgroundColor = HabitatColors.surfacePrimary,
    this.padding = const EdgeInsets.all(HabitatSpacing.l),
    this.margin = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: HabitatRadii.radiusXL,
        border: Border.all(
          color: borderColor ?? HabitatColors.surfaceBorder,
          width: borderWidth,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: HabitatRadii.radiusXL,
        child: card,
      );
    }
    return card;
  }
}
