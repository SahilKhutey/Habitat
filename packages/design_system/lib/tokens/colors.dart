// Semantic Color Architecture for Habitat Personal Growth Environment
import 'package:flutter/material.dart';

class AppColors {
  // Official Guidelines Palette
  static const Color forest = Color(0xFF0F2E1F);         // #0F2E1F - Primary Forest
  static const Color habitatGreen = Color(0xFF1E5B38);   // #1E5B38 - Secondary Green
  static const Color growthGreen = Color(0xFF4CAF50);    // #4CAF50 - Growth Accent & Success
  static const Color youngLeaf = Color(0xFFA8D08D);      // #A8D08D - Highlights & Subtle Accents
  static const Color habitatCream = Color(0xFFF7F7F2);   // #F7F7F2 - Light Canvas & High-contrast Text

  // Dark Mode Semantic Palette (#081C13 Quiet Night Environment)
  static const Color darkBackground = Color(0xFF081C13); // #081C13
  static const Color darkSurface = Color(0xFF10291E);    // #10291E
  static const Color darkSurfaceElevated = Color(0xFF163525); // #163525
  static const Color darkBorder = Color(0xFF1E4230);
  static const Color darkTextPrimary = habitatCream;     // #F7F7F2
  static const Color darkTextSecondary = Color(0xFFB7C6BC); // #B7C6BC
  static const Color darkTextMuted = Color(0xFF6E8577);

  // Light Mode Semantic Palette
  static const Color lightBackground = habitatCream;     // #F7F7F2
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceElevated = Color(0xFFEBF2ED);
  static const Color lightBorder = Color(0xFFD4E2D8);
  static const Color lightTextPrimary = forest;          // #0F2E1F
  static const Color lightTextSecondary = Color(0xFF3E5C4A);
  static const Color lightTextMuted = Color(0xFF759482);

  // Semantic Status Tokens
  static const Color primary = habitatGreen;
  static const Color growth = growthGreen;
  static const Color growthSoft = Color(0xFF1A472E);
  static const Color warning = youngLeaf;
  static const Color error = Color(0xFFFF5252);
  static const Color info = youngLeaf;
  static const Color streakFlame = growthGreen;
  static const Color reminderAlert = youngLeaf;
  static const Color crimsonAlert = Color(0xFFFF5252);

  // Aliases for Backwards Compatibility
  static const Color deepForest = forest;
  static const Color forestGreen = habitatGreen;
  static const Color sageGreen = youngLeaf;
  static const Color offWhite = habitatCream;
  static const Color lightPrimary = habitatGreen;
  static const Color lightSecondary = growthGreen;
  static const Color darkPrimary = growthGreen;
  static const Color darkSecondary = youngLeaf;
}
