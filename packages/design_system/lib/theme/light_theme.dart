// Light Theme Architecture for Habitat
import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    primaryColor: AppColors.lightPrimary,
    cardColor: AppColors.lightSurface,
    dividerColor: AppColors.lightBorder,
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightPrimary,
      secondary: AppColors.lightSecondary,
      surface: AppColors.lightSurface,
      error: AppColors.crimsonAlert,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: AppColors.lightTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.radiusLarge),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
      ),
    ),
  );
}
