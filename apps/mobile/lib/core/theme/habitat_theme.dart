// Habitat Brand Theme (Deep Forest, Growth Green & Crisp Off-White)
import 'package:flutter/material.dart';

class HabitatTheme {
  // Brand Color Palette from Official Guidelines
  static const Color deepForest = Color(0xFF0F2E1F); // #0F2E1F
  static const Color forestGreen = Color(0xFF1E5B38); // #1E5B38
  static const Color growthGreen = Color(0xFF4CAF50); // #4CAF50 - Primary Accent & Action
  static const Color sageGreen = Color(0xFFA8D08D);   // #A8D08D - Secondary & Badges
  static const Color offWhite = Color(0xFFF7F7F2);    // #F7F7F2 - Light Background / Text

  // Dark Theme Surfaces
  static const Color background = Color(0xFF0A1F15); // Rich Deep Obsidian Green
  static const Color surfacePrimary = Color(0xFF0F2E1F);
  static const Color surfaceSecondary = Color(0xFF163E2B);
  static const Color surfaceElevated = Color(0xFF1E5B38);
  static const Color surfaceBorder = Color(0xFF285E42);

  // Semantic Action Accents
  static const Color primaryAction = growthGreen;
  static const Color streakFlame = growthGreen;
  static const Color growthTrending = sageGreen;
  static const Color reminderAlert = Color(0xFF81C784);

  // Typography Tokens
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0D0C0);
  static const Color textMuted = Color(0xFF5E8570);
  static const Color textDark = Color(0xFF0F2E1F);

  static const String fontHeading = 'Poppins';
  static const String fontBody = 'Inter';

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: growthGreen,
      cardColor: surfacePrimary,
      dividerColor: surfaceBorder,
      colorScheme: const ColorScheme.dark(
        primary: growthGreen,
        secondary: sageGreen,
        surface: surfacePrimary,
        error: Color(0xFFFF5252),
        onPrimary: Color(0xFF0F2E1F),
        onSecondary: Color(0xFF0F2E1F),
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
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: growthGreen),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfacePrimary,
        selectedItemColor: growthGreen,
        unselectedItemColor: textMuted,
        selectedLabelStyle: TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontFamily: fontBody, fontWeight: FontWeight.normal, fontSize: 11),
      ),
      cardTheme: CardTheme(
        color: surfacePrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: growthGreen,
          foregroundColor: const Color(0xFF0F2E1F),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      scaffoldBackgroundColor: offWhite,
      primaryColor: forestGreen,
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE0EAE3),
      colorScheme: const ColorScheme.light(
        primary: forestGreen,
        secondary: growthGreen,
        surface: Colors.white,
        error: Color(0xFFD32F2F),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: offWhite,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontHeading,
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: forestGreen),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: forestGreen,
        unselectedItemColor: Color(0xFF8A9E93),
        selectedLabelStyle: TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontFamily: fontBody, fontWeight: FontWeight.normal, fontSize: 11),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD8E4DC), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forestGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
