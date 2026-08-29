// Habitat Design System - Responsive Layout Builder
import 'package:flutter/material.dart';
import '../tokens/breakpoints.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= HabitatBreakpoints.desktop && desktop != null) {
      return desktop!(context);
    } else if (width >= HabitatBreakpoints.mobile && tablet != null) {
      return tablet!(context);
    } else {
      return mobile(context);
    }
  }
}
