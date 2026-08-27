// Semantic Color System for Habitat / Discipline Platform
import 'package:flutter/material.dart';

class AppColors {
  // Light Palette Tokens
  static const Color lightPrimary = Color(0xFFFF9500); // Amber Focus
  static const Color lightSecondary = Color(0xFF007AFF);
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFE5E5EA);
  static const Color lightBorder = Color(0xFFD1D1D6);
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF6C6C70);
  static const Color lightTextMuted = Color(0xFF8E8E93);

  // Dark Palette Tokens (OLED Tactical)
  static const Color darkPrimary = Color(0xFFFF9500); // Amber Focus
  static const Color darkSecondary = Color(0xFF0A84FF);
  static const Color darkBackground = Color(0xFF0A0A0C); // Obsidian
  static const Color darkSurface = Color(0xFF141418); // Gunmetal
  static const Color darkSurfaceElevated = Color(0xFF1C1C22);
  static const Color darkBorder = Color(0xFF282832);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkTextMuted = Color(0xFF48484A);

  // Semantic Action Accents (Identical Across Themes)
  static const Color crimsonAlert = Color(0xFFFF3B30); // Wake-up Siren & Escalation
  static const Color crimsonAlertSubtle = Color(0xFF2E1414);
  static const Color amberFocus = Color(0xFFFF9500); // Active Missions & Streaks
  static const Color amberFocusSubtle = Color(0xFF2E2214);
  static const Color emeraldVictory = Color(0xFF34C759); // Mission Verified & XP
  static const Color emeraldVictorySubtle = Color(0xFF142E1A);
  static const Color cyanTelemetry = Color(0xFF00F2FE); // AI & Sensor Telemetry
  static const Color purpleGraceVault = Color(0xFF5856D6); // Grace Tokens & Shields

  // Semantic Status Tokens
  static const Color success = emeraldVictory;
  static const Color warning = amberFocus;
  static const Color error = crimsonAlert;
  static const Color info = cyanTelemetry;
}
