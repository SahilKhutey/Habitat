import 'package:flutter/material.dart';

/// Semantic elevation values. Habitat prefers borders and surface contrast;
/// elevation is intentionally restrained.
abstract final class AppElevation {
  static const double none = 0;
  static const double low = 1;
  static const double medium = 3;
  static const double high = 6;

  // Semantic aliases
  static const double subtle = 1.0;
  static const double card = 2.0;
  static const double modal = 8.0;

  static const BoxShadow subtleShadow = BoxShadow(
    blurRadius: 18,
    offset: Offset(0, 6),
  );
}
