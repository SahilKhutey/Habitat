// Semantic Radius & Elevation & Duration & Breakpoint Tokens
import 'package:flutter/material.dart';

class AppRadii {
  static const double none = 0.0;
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double extraLarge = 20.0;
  static const double circular = 999.0;

  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(small));
  static const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(large));
  static const BorderRadius radiusExtraLarge = BorderRadius.all(Radius.circular(extraLarge));
  static const BorderRadius radiusCircular = BorderRadius.all(Radius.circular(circular));
}

class AppElevation {
  static const double none = 0.0;
  static const double low = 2.0;
  static const double medium = 4.0;
  static const double high = 8.0;
  static const double modal = 16.0;
}

class AppDurations {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration sirenPulse = Duration(milliseconds: 800);
}

class AppBreakpoints {
  static const double mobile = 600.0;
  static const double tablet = 1024.0;
  static const double desktop = 1440.0;

  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < mobile;
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < tablet;
  }
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= tablet;
}
