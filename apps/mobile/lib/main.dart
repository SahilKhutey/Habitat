// Habitat Flutter Application Entry Point & Navigation Experience
import 'package:flutter/material.dart';
import 'core/design_system/responsive/adaptive_scaffold.dart';
import 'core/theme/habitat_theme.dart';
import 'database/local_database.dart';
import 'features/health/presentation/pages/health_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/progress/presentation/pages/progress_page.dart';
import 'features/tasks/presentation/pages/alarm_page.dart';
import 'features/tasks/presentation/pages/tasks_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocalDatabase.instance.initializeDefaultTemplates();
  runApp(const HabitatApp());
}

class HabitatApp extends StatelessWidget {
  const HabitatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitat',
      debugShowCheckedModeBanner: false,
      theme: HabitatTheme.darkTheme,
      home: const HabitatHomeScreen(),
    );
  }
}

class HabitatHomeScreen extends StatefulWidget {
  const HabitatHomeScreen({super.key});

  @override
  State<HabitatHomeScreen> createState() => _HabitatHomeScreenState();
}

class _HabitatHomeScreenState extends State<HabitatHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return HabitatAdaptiveScaffold(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
      child: _buildCurrentTab(),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return HomePage(
          onOpenTasks: () => setState(() => _selectedIndex = 1),
          onOpenHealth: () => setState(() => _selectedIndex = 2),
          onOpenProgress: () => setState(() => _selectedIndex = 3),
          onOpenProfile: () => setState(() => _selectedIndex = 4),
          onOpenNotifications: _openActiveAlarmScreen,
        );
      case 1:
        return const TasksPage();
      case 2:
        return const HealthPage();
      case 3:
        return const ProgressPage();
      case 4:
        return const ProfilePage();
      default:
        return HomePage(
          onOpenTasks: () => setState(() => _selectedIndex = 1),
          onOpenHealth: () => setState(() => _selectedIndex = 2),
          onOpenProgress: () => setState(() => _selectedIndex = 3),
          onOpenProfile: () => setState(() => _selectedIndex = 4),
          onOpenNotifications: _openActiveAlarmScreen,
        );
    }
  }

  void _openActiveAlarmScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AlarmPage()),
    );
  }
}
