// Responsive Layout Container & App Shell
import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/breakpoints.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (AppBreakpoints.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

class AppShell extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final Widget body;

  const AppShell({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = AppBreakpoints.isDesktop(context);

    if (isDesktop) {
      // Desktop / Web Navigation Rail Sidebar
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              selectedIndex: currentIndex,
              onDestinationSelected: onIndexChanged,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: AppColors.amberFocus),
              unselectedIconTheme: IconThemeData(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Home')),
                NavigationRailDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: Text('Tasks')),
                NavigationRailDestination(icon: Icon(Icons.alarm_outlined), selectedIcon: Icon(Icons.alarm), label: Text('Alarms')),
                NavigationRailDestination(icon: Icon(Icons.show_chart_outlined), selectedIcon: Icon(Icons.show_chart), label: Text('Progress')),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    // Mobile Bottom Navigation
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onIndexChanged,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        selectedItemColor: AppColors.amberFocus,
        unselectedItemColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm_outlined), activeIcon: Icon(Icons.alarm), label: 'Alarms'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart_outlined), activeIcon: Icon(Icons.show_chart), label: 'Progress'),
        ],
      ),
    );
  }
}
