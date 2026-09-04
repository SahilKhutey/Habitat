// Habitat Design System - Standardized Input Fields
import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/typography.dart';

class HabitatTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const HabitatTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: HabitatTypography.fontBody,
        fontSize: HabitatTypography.body,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: HabitatTypography.fontHeading,
          color: HabitatColors.textSecondary,
          fontSize: HabitatTypography.bodySmall,
        ),
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: HabitatTypography.fontBody,
          color: HabitatColors.textMuted,
          fontSize: HabitatTypography.bodySmall,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: HabitatColors.surfacePrimary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HabitatRadius.md),
          borderSide: const BorderSide(color: HabitatColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HabitatRadius.md),
          borderSide: const BorderSide(color: HabitatColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HabitatRadius.md),
          borderSide:
              const BorderSide(color: HabitatColors.growthGreen, width: 1.5),
        ),
      ),
    );
  }
}

class HabitatNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? suffixText;

  const HabitatNumberField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.suffixText,
  });

  @override
  Widget build(BuildContext context) {
    return HabitatTextField(
      controller: controller,
      label: label,
      hint: hint,
      keyboardType: TextInputType.number,
      suffixIcon: suffixText != null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                suffixText!,
                style: const TextStyle(
                  fontFamily: HabitatTypography.fontHeading,
                  color: HabitatColors.youngLeaf,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}
