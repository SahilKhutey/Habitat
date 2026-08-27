// Reusable Form Input Components
import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';
import '../../tokens/radii.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool isPassword;
  final TextInputType keyboardType;

  const AppTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.errorText,
    this.onChanged,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            errorText: errorText,
            filled: true,
            fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: AppRadii.radiusLarge,
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.radiusLarge,
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadii.radiusLarge,
              borderSide: BorderSide(color: AppColors.amberFocus, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
