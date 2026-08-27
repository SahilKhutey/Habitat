// App Theme Controller & Aggregator
import 'package:flutter/material.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

class AppTheme {
  static ThemeData get light => buildLightTheme();
  static ThemeData get dark => buildDarkTheme();
  static const ThemeMode defaultMode = ThemeMode.system;
}
