// Habitat Responsive Layout Primitives (Phase 17)
import 'package:flutter/material.dart';
import '../../tokens/breakpoints.dart';
import '../../tokens/spacing.dart';

/// Standard page wrapper providing Safe Area, responsive margins,
/// maximum desktop content constraint (1200px), and optional scrolling.
class HabitatPage extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;
  final double maxContentWidth;
  final Color? backgroundColor;

  const HabitatPage({
    super.key,
    required this.child,
    this.scrollable = true,
    this.padding,
    this.maxContentWidth = 1200.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < AppBreakpoints.mobile;
    final isTablet = screenWidth >= AppBreakpoints.mobile && screenWidth < AppBreakpoints.desktop;

    final defaultPadding = EdgeInsets.symmetric(
      horizontal: isMobile
          ? HabitatSpacing.md
          : (isTablet ? HabitatSpacing.lg : HabitatSpacing.xl),
      vertical: HabitatSpacing.md,
    );

    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(
          padding: padding ?? defaultPadding,
          child: child,
        ),
      ),
    );

    if (scrollable) {
      content = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: content,
      );
    }

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: content,
      ),
    );
  }
}

/// Adaptive Grid calculating columns dynamically based on available width:
/// <600px -> 1 column
/// 600-1199px -> 2 columns
/// >=1200px -> up to maxColumns (default 4)
class HabitatAdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double minItemWidth;
  final int maxColumns;

  const HabitatAdaptiveGrid({
    super.key,
    required this.children,
    this.spacing = HabitatSpacing.md,
    this.runSpacing = HabitatSpacing.md,
    this.minItemWidth = 280.0,
    this.maxColumns = 4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        int columns = (availableWidth / (minItemWidth + spacing)).floor();
        if (availableWidth < AppBreakpoints.mobile) {
          columns = 1;
        } else if (availableWidth < AppBreakpoints.desktop) {
          columns = columns.clamp(1, 2);
        } else {
          columns = columns.clamp(1, maxColumns);
        }

        if (columns <= 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) SizedBox(height: runSpacing),
              ],
            ],
          );
        }

        final itemWidth = (availableWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((c) => SizedBox(width: itemWidth, child: c)).toList(),
        );
      },
    );
  }
}
