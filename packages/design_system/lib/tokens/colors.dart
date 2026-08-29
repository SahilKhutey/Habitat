// Semantic Color System for Habitat Official Brand Palette
import 'package:flutter/material.dart';

class AppColors {
  // Official Brand Palette Tokens
  static const Color deepForest = Color(0xFF0F2E1F); // #0F2E1F - Primary Brand Surface / Dark BG
  static const Color forestGreen = Color(0xFF1E5B38); // #1E5B38 - Primary Brand Tone
  static const Color growthGreen = Color(0xFF4CAF50); // #4CAF50 - Active Growth & Positive Accent
  static const Color sageGreen = Color(0xFFA8D08D);   // #A8D08D - Secondary Highlight & Badges
  static const Color offWhite = Color(0xFFF7F7F2);    // #F7F7F2 - Light Canvas & Text Light

  // Light Palette Tokens
  static const Color lightPrimary = forestGreen;
  static const Color lightSecondary = growthGreen;
  static const Color lightBackground = offWhite;
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceElevated = Color(0xFFE8EFEA);
  static const Color lightBorder = Color(0xFFD3E0D7);
  static const Color lightTextPrimary = deepForest;
  static const Color lightTextSecondary = Color(0xFF4A6B58);
  static const Color lightTextMuted = Color(0xFF7D9B89);

  // Dark Palette Tokens (Deep Forest Luxury)
  static const Color darkPrimary = growthGreen;
  static const Color darkSecondary = sageGreen;
  static const Color darkBackground = Color(0xFF0A1F15); // Deep Obsidian Forest
  static const Color darkSurface = deepForest; // #0F2E1F
  static const Color darkSurfaceElevated = forestGreen; // #1E5B38
  static const Color darkBorder = Color(0xFF285E42);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFB0D0C0);
  static const Color darkTextMuted = Color(0xFF5E8570);

  // Semantic Action Accents
  static const Color streakFlame = growthGreen;
  static const Color growthTrending = sageGreen;
  static const Color reminderAlert = Color(0xFF81C784);
  static const Color crimsonAlert = Color(0xFFFF5252);
  static const Color emeraldVictory = growthGreen;

  // Semantic Status Tokens
  static const Color success = growthGreen;
  static const Color warning = sageGreen;
  static const Color error = crimsonAlert;
  static const Color info = sageGreen;
}
