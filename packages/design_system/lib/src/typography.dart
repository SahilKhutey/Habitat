// Habitat Tactical Typography Hierarchy
import 'package:flutter/material.dart';
import 'colors.dart';

class HabitatTypography {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    color: HabitatColors.textPrimary,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.0,
    color: HabitatColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
    color: HabitatColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.1,
    color: HabitatColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.0,
    color: HabitatColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
    color: HabitatColors.textSecondary,
  );

  static const TextStyle monospaceCounter = TextStyle(
    fontFamily: 'monospace',
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.5,
    color: HabitatColors.textPrimary,
  );
}
