// Habitat Design System - Responsive Breakpoint Tokens
import 'package:flutter/widgets.dart';

abstract final class HabitatBreakpoints {
  static const double mobile = 600.0;
  static const double tablet = 900.0;
  static const double desktop = 1200.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}
