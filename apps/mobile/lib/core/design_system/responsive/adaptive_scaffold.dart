// Habitat Design System - Adaptive Navigation Scaffold (Mobile BottomNav & Desktop NavRail)
import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';

class HabitatAdaptiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const HabitatAdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < 700) {
      return Scaffold(
        backgroundColor: HabitatColors.backgroundDark,
        body: child,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: HabitatColors.surfaceBorder, width: 1)),
          ),
          child: NavigationBar(
            backgroundColor: HabitatColors.surfacePrimary,
            indicatorColor: HabitatColors.habitatGreen,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.wb_sunny_outlined, color: HabitatColors.textMuted),
                selectedIcon: Icon(Icons.wb_sunny, color: HabitatColors.growthGreen),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.checklist_rtl, color: HabitatColors.textMuted),
                selectedIcon: Icon(Icons.checklist_rtl, color: HabitatColors.growthGreen),
                label: 'Tasks',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_outline, color: HabitatColors.textMuted),
                selectedIcon: Icon(Icons.favorite, color: HabitatColors.growthGreen),
                label: 'Health',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined, color: HabitatColors.textMuted),
                selectedIcon: Icon(Icons.insights, color: HabitatColors.growthGreen),
                label: 'Progress',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline, color: HabitatColors.textMuted),
                selectedIcon: Icon(Icons.person, color: HabitatColors.growthGreen),
                label: 'Profile',
              ),
            ],
          ),
        ),
      );
    }

    // Tablet & Desktop Layout (>= 700 px)
    return Scaffold(
      backgroundColor: HabitatColors.backgroundDark,
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: HabitatColors.surfacePrimary,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            indicatorColor: HabitatColors.habitatGreen,
            labelType: NavigationRailLabelType.all,
            selectedLabelTextStyle: const TextStyle(
              fontFamily: HabitatTypography.fontHeading,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: HabitatColors.growthGreen,
            ),
            unselectedLabelTextStyle: const TextStyle(
              fontFamily: HabitatTypography.fontBody,
              fontSize: 11,
              color: HabitatColors.textMuted,
            ),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: HabitatColors.habitatGreen,
                ),
                child: const Icon(Icons.eco, color: HabitatColors.growthGreen, size: 26),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.wb_sunny_outlined, color: HabitatColors.textMuted),
                selectedIcon: Icon(Icons.wb_sunny, color: HabitatColors.growthGreen),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.checklist_rtl, color: HabitatColors.textMuted),
                selectedIcon: Icon(Icons.checklist_rtl, color: HabitatColors.growthGreen),
                label: Text('Tasks'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.favorite_outline, color: HabitatColors.textMuted),
                selectedIcon: Icon(Icons.favorite, color: HabitatColors.growthGreen),
                label: Text('Health'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.insights_outlined, color: HabitatColors.textMuted),
                selectedIcon: Icon(Icons.insights, color: HabitatColors.growthGreen),
                label: Text('Progress'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline, color: HabitatColors.textMuted),
                selectedIcon: Icon(Icons.person, color: HabitatColors.growthGreen),
                label: Text('Profile'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, color: HabitatColors.surfaceBorder),
          Expanded(child: child),
        ],
      ),
    );
  }
}
