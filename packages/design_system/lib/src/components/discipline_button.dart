// Discipline Button Component with Haptics and Loading States
import 'package:flutter/material.dart';
import '../colors.dart';
import '../spacing.dart';

enum DisciplineButtonVariant { primary, alert, victory, outline }

class DisciplineButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final DisciplineButtonVariant variant;
  final double height;

  const DisciplineButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.variant = DisciplineButtonVariant.primary,
    this.height = 54.0,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide side = BorderSide.none;

    switch (variant) {
      case DisciplineButtonVariant.primary:
        bg = HabitatColors.amberFocus;
        fg = Colors.black;
        break;
      case DisciplineButtonVariant.alert:
        bg = HabitatColors.crimsonAlert;
        fg = Colors.white;
        break;
      case DisciplineButtonVariant.victory:
        bg = HabitatColors.emeraldVictory;
        fg = Colors.black;
        break;
      case DisciplineButtonVariant.outline:
        bg = Colors.transparent;
        fg = Colors.white;
        side = const BorderSide(color: HabitatColors.surfaceBorder);
        break;
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          side: side,
          shape: const RoundedRectangleBorder(borderRadius: HabitatRadii.radiusL),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: fg, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: fg),
                    const SizedBox(width: HabitatSpacing.xs),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
