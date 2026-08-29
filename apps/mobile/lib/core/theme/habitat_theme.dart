// Habitat Brand Theme (Calm, Premium Personal Growth Environment)
import 'package:flutter/material.dart';

class HabitatTheme {
  // Official Guidelines Palette
  static const Color forest = Color(0xFF0F2E1F);         // #0F2E1F - Primary Forest
  static const Color habitatGreen = Color(0xFF1E5B38);   // #1E5B38 - Secondary Green
  static const Color growthGreen = Color(0xFF4CAF50);    // #4CAF50 - Growth Accent & Success
  static const Color youngLeaf = Color(0xFFA8D08D);      // #A8D08D - Highlights & Subtle Accents
  static const Color habitatCream = Color(0xFFF7F7F2);   // #F7F7F2 - Light Canvas & High-contrast Text

  // Dark Mode Semantic Surfaces (#081C13 Quiet Night Environment)
  static const Color background = Color(0xFF081C13);     // #081C13
  static const Color surfacePrimary = Color(0xFF10291E);  // #10291E
  static const Color surfaceSecondary = Color(0xFF163525);// #163525
  static const Color surfaceBorder = Color(0xFF1E4230);

  // Typography Tokens
  static const Color textPrimary = habitatCream;         // #F7F7F2
  static const Color textSecondary = Color(0xFFB7C6BC);   // #B7C6BC
  static const Color textMuted = Color(0xFF6E8577);
  static const Color textDark = forest;

  static const String fontHeading = 'Poppins';
  static const String fontBody = 'Inter';

  // Backward compatibility aliases
  static const Color deepForest = forest;
  static const Color forestGreen = habitatGreen;
  static const Color sageGreen = youngLeaf;
  static const Color offWhite = habitatCream;

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
        secondary: youngLeaf,
        surface: surfacePrimary,
        error: Color(0xFFFF5252),
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
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: habitatGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: habitatGreen),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: habitatGreen,
        unselectedItemColor: Color(0xFF759482),
        selectedLabelStyle: TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontFamily: fontBody, fontWeight: FontWeight.normal, fontSize: 11),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFD4E2D8), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: habitatGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
