// Habitat Tactical Dark Theme (High-Contrast Discipline Palette)
import 'package:flutter/material.dart';

class HabitatTheme {
  static const Color background = Color(0xFF0A0A0C);
  static const Color surfacePrimary = Color(0xFF141419);
  static const Color surfaceSecondary = Color(0xFF1F1F26);
  static const Color surfaceBorder = Color(0xFF2E2E38);

  static const Color crimsonAlert = Color(0xFFFF3B30);
  static const Color amberFocus = Color(0xFFFF9500);
  static const Color emeraldVictory = Color(0xFF34C759);
  static const Color electricBlue = Color(0xFF0A84FF);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textMuted = Color(0xFF48484A);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: crimsonAlert,
      colorScheme: const ColorScheme.dark(
        primary: crimsonAlert,
        secondary: amberFocus,
        surface: surfacePrimary,
        error: crimsonAlert,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardTheme(
        color: surfacePrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
      ),
    );
  }
}
