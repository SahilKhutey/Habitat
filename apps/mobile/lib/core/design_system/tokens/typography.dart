// Habitat Design System - Typography Tokens
import 'package:flutter/material.dart';

abstract final class HabitatTypography {
  static const String fontHeading = 'Poppins';
  static const String fontBody = 'Inter';

  // Font Sizes
  static const double display = 36.0;
  static const double headline = 28.0;
  static const double title = 22.0;
  static const double subtitle = 18.0;
  static const double bodyLarge = 16.0;
  static const double body = 14.0;
  static const double bodySmall = 12.0;
  static const double label = 11.0;
  static const double caption = 10.0;

  // Text Styles
  static const TextStyle displayStyle = TextStyle(
    fontFamily: fontHeading,
    fontSize: display,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineStyle = TextStyle(
    fontFamily: fontHeading,
    fontSize: headline,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );

  static const TextStyle titleStyle = TextStyle(
    fontFamily: fontHeading,
    fontSize: title,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle titleMedium = titleStyle;

  static const TextStyle subtitleStyle = TextStyle(
    fontFamily: fontHeading,
    fontSize: subtitle,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLargeStyle = TextStyle(
    fontFamily: fontBody,
    fontSize: bodyLarge,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontFamily: fontBody,
    fontSize: body,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySmallStyle = TextStyle(
    fontFamily: fontBody,
    fontSize: bodySmall,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle labelStyle = TextStyle(
    fontFamily: fontHeading,
    fontSize: label,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  );

  static const TextStyle captionStyle = TextStyle(
    fontFamily: fontBody,
    fontSize: caption,
    fontWeight: FontWeight.w400,
  );
}
