// Habitat Tactical OLED Dark ThemeData
import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';

class HabitatThemeData {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: HabitatColors.background,
      primaryColor: HabitatColors.amberFocus,
      cardColor: HabitatColors.surfacePrimary,
      dividerColor: HabitatColors.surfaceBorder,
      colorScheme: const ColorScheme.dark(
        primary: HabitatColors.amberFocus,
        secondary: HabitatColors.crimsonAlert,
        surface: HabitatColors.surfacePrimary,
        error: HabitatColors.crimsonAlert,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: HabitatColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: HabitatColors.background,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: HabitatTypography.headline,
        iconTheme: IconThemeData(color: HabitatColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HabitatColors.amberFocus,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: HabitatSpacing.xl, vertical: HabitatSpacing.m),
          shape: const RoundedRectangleBorder(borderRadius: HabitatRadii.radiusL),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HabitatColors.textPrimary,
          side: const BorderSide(color: HabitatColors.surfaceBorder),
          padding: const EdgeInsets.symmetric(horizontal: HabitatSpacing.xl, vertical: HabitatSpacing.m),
          shape: const RoundedRectangleBorder(borderRadius: HabitatRadii.radiusL),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}
