// Reusable AppButton Component
import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';
import '../../tokens/radii.dart';

enum AppButtonVariant { primary, secondary, tertiary, danger, success, outline, icon, text, critical }

class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final AppButtonVariant variant;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.variant = AppButtonVariant.primary,
    this.height = 54.0,
  });

  factory AppButton.primary({
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return AppButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: AppButtonVariant.primary,
    );
  }

  factory AppButton.danger({
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return AppButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: AppButtonVariant.danger,
    );
  }

  factory AppButton.success({
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return AppButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: AppButtonVariant.success,
    );
  }

  factory AppButton.outline({
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return AppButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: AppButtonVariant.outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide side = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppColors.amberFocus;
        fg = Colors.black;
        break;
      case AppButtonVariant.danger:
      case AppButtonVariant.critical:
        bg = AppColors.crimsonAlert;
        fg = Colors.white;
        break;
      case AppButtonVariant.success:
        bg = AppColors.emeraldVictory;
        fg = Colors.black;
        break;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
        side = BorderSide(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder,
        );
        break;
      default:
        bg = AppColors.amberFocus;
        fg = Colors.black;
    }

    final effectiveOnPressed = (isLoading || isDisabled) ? null : onPressed;

    return Semantics(
      button: true,
      enabled: !isDisabled && !isLoading,
      label: label,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            disabledBackgroundColor: bg.withOpacity(0.3),
            disabledForegroundColor: fg.withOpacity(0.3),
            elevation: 0,
            side: side,
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.radiusLarge),
          ),
          onPressed: effectiveOnPressed,
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
                      const SizedBox(width: AppSpacing.sm),
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
      ),
    );
  }
}
