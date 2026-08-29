// Habitat Design System - Layout & Padding Primitives
import 'package:flutter/material.dart';
import '../../tokens/spacing.dart';

class HabitatContentContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const HabitatContentContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class HabitatPagePadding extends StatelessWidget {
  final Widget child;
  final double horizontal;
  final double vertical;

  const HabitatPagePadding({
    super.key,
    required this.child,
    this.horizontal = HabitatSpacing.lg,
    this.vertical = HabitatSpacing.xl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: child,
    );
  }
}
