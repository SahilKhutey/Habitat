// Dark OLED Tactical Theme Architecture for Habitat
import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    primaryColor: AppColors.darkPrimary,
    cardColor: AppColors.darkSurface,
    dividerColor: AppColors.darkBorder,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      secondary: AppColors.darkSecondary,
      surface: AppColors.darkSurface,
      error: AppColors.crimsonAlert,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: AppColors.darkTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.radiusLarge),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
      ),
    ),
  );
}
