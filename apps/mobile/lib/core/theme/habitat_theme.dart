// Habitat Brand Theme (Calm, Premium Personal Growth Environment)
import 'package:flutter/material.dart';
import '../design_system/theme/habitat_theme_extension.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/radii.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/typography.dart';

class HabitatTheme {
  // Official Guidelines Palette
  static const Color forest = HabitatColors.forest;
  static const Color habitatGreen = HabitatColors.habitatGreen;
  static const Color growthGreen = HabitatColors.growthGreen;
  static const Color youngLeaf = HabitatColors.youngLeaf;
  static const Color habitatCream = HabitatColors.habitatCream;

  // Dark Mode Semantic Surfaces (#081C13 Quiet Night Environment)
  static const Color background = HabitatColors.backgroundDark;
  static const Color surfacePrimary = HabitatColors.surfacePrimary;
  static const Color surfaceSecondary = HabitatColors.surfaceSecondary;
  static const Color surfaceBorder = HabitatColors.surfaceBorder;
  static const Color borderSubtle = surfaceBorder;

  // Typography Tokens
  static const Color textPrimary = HabitatColors.textPrimary;
  static const Color textSecondary = HabitatColors.textSecondary;
  static const Color textMuted = HabitatColors.textMuted;
  static const Color textDark = HabitatColors.textDark;

  static const String fontHeading = HabitatTypography.fontHeading;
  static const String fontBody = HabitatTypography.fontBody;

  // Backward compatibility aliases
  static const Color deepForest = forest;
  static const Color forestGreen = habitatGreen;
  static const Color sageGreen = youngLeaf;
  static const Color offWhite = habitatCream;
  static const Color amberFocus = HabitatColors.warning;
  static const Color emeraldVictory = HabitatColors.success;
  static const Color crimsonAlert = HabitatColors.danger;
  static const Color cyanTelemetry = HabitatColors.info;
  static const Color purpleGraceVault = HabitatColors.accentPurple;
  static const Color primaryAction = HabitatColors.growthGreen;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: growthGreen,
      cardColor: surfacePrimary,
      dividerColor: surfaceBorder,
      extensions: const [HabitatThemeExtension.dark],
      colorScheme: const ColorScheme.dark(
        primary: growthGreen,
        secondary: youngLeaf,
        surface: surfacePrimary,
        error: HabitatColors.danger,
        onPrimary: forest,
        onSecondary: forest,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontHeading,
          color: textPrimary,
          fontSize: HabitatTypography.title,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: growthGreen),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfacePrimary,
        selectedItemColor: growthGreen,
        unselectedItemColor: textMuted,
        selectedLabelStyle: TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.w600, fontSize: HabitatTypography.label),
        unselectedLabelStyle: TextStyle(fontFamily: fontBody, fontWeight: FontWeight.normal, fontSize: HabitatTypography.label),
      ),
      cardTheme: CardThemeData(
        color: surfacePrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabitatRadius.lg),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: habitatGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: HabitatSpacing.xl, vertical: HabitatSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HabitatRadius.md)),
          textStyle: const TextStyle(
            fontFamily: fontHeading,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: habitatCream,
      primaryColor: habitatGreen,
      cardColor: Colors.white,
      dividerColor: const Color(0xFFD4E2D8),
      extensions: const [HabitatThemeExtension.light],
      colorScheme: const ColorScheme.light(
        primary: habitatGreen,
        secondary: growthGreen,
        surface: Colors.white,
        error: Color(0xFFD32F2F),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: habitatCream,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontHeading,
          color: textDark,
          fontSize: HabitatTypography.title,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: habitatGreen),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: habitatGreen,
        unselectedItemColor: Color(0xFF759482),
        selectedLabelStyle: TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.w600, fontSize: HabitatTypography.label),
        unselectedLabelStyle: TextStyle(fontFamily: fontBody, fontWeight: FontWeight.normal, fontSize: HabitatTypography.label),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabitatRadius.lg),
          side: const BorderSide(color: Color(0xFFD4E2D8), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: habitatGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: HabitatSpacing.xl, vertical: HabitatSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HabitatRadius.md)),
          textStyle: const TextStyle(
            fontFamily: fontHeading,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
