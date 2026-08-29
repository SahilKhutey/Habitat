// Habitat Semantic Theme Extension
import 'dart:ui';
import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';

@immutable
class HabitatThemeExtension extends ThemeExtension<HabitatThemeExtension> {
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color surfaceBorder;
  final double cardRadius;

  const HabitatThemeExtension({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.surfaceBorder,
    required this.cardRadius,
  });

  static const HabitatThemeExtension dark = HabitatThemeExtension(
    success: HabitatColors.success,
    warning: HabitatColors.warning,
    danger: HabitatColors.danger,
    info: HabitatColors.info,
    surfaceBorder: HabitatColors.surfaceBorder,
    cardRadius: HabitatRadius.lg,
  );

  static const HabitatThemeExtension light = HabitatThemeExtension(
    success: Color(0xFF2E7D32),
    warning: Color(0xFFF9A825),
    danger: Color(0xFFC62828),
    info: Color(0xFF0288D1),
    surfaceBorder: Color(0xFFD4E2D8),
    cardRadius: HabitatRadius.lg,
  );

  @override
  HabitatThemeExtension copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? surfaceBorder,
    double? cardRadius,
  }) {
    return HabitatThemeExtension(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      surfaceBorder: surfaceBorder ?? this.surfaceBorder,
      cardRadius: cardRadius ?? this.cardRadius,
    );
  }

  @override
  HabitatThemeExtension lerp(
    covariant HabitatThemeExtension? other,
    double t,
  ) {
    if (other == null) return this;

    return HabitatThemeExtension(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
    );
  }
}
