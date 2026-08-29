// Habitat Design System - Botanical Obsidian Color Palette
import 'package:flutter/material.dart';

abstract final class HabitatColors {
  // Primary Botanical Identity
  static const Color forest = Color(0xFF0F2E1F);
  static const Color habitatGreen = Color(0xFF1E5B38);
  static const Color growthGreen = Color(0xFF4CAF50);
  static const Color youngLeaf = Color(0xFFA8D08D);
  static const Color habitatCream = Color(0xFFF7F7F2);

  // Dark Environment Surfaces (#081C13)
  static const Color backgroundDark = Color(0xFF081C13);
  static const Color surfacePrimary = Color(0xFF10291E);
  static const Color surfaceSecondary = Color(0xFF163525);
  static const Color surfaceBorder = Color(0xFF1E4230);

  // Text Colors
  static const Color textPrimary = habitatCream;
  static const Color textSecondary = Color(0xFFB7C6BC);
  static const Color textMuted = Color(0xFF6E8577);
  static const Color textDark = forest;

  // Semantic Signals
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB703);
  static const Color danger = Color(0xFFFF5252);
  static const Color info = Color(0xFF4CC9F0);
  static const Color accentPurple = Color(0xFF7209B7);
  static const Color accentPink = Color(0xFFF72585);
}
