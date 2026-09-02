// Habitat Flutter Application Entry Point & Navigation Experience
import 'package:flutter/material.dart';
import 'core/alarm/native_alarm_service.dart';
import 'core/design_system/responsive/adaptive_scaffold.dart';
import 'core/theme/habitat_theme.dart';
import 'database/local_database.dart';
import 'features/health/presentation/pages/health_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/progress/presentation/pages/progress_page.dart';
import 'features/tasks/domain/services/alarm_service.dart';
import 'features/tasks/presentation/pages/alarm_page.dart';
import 'features/tasks/presentation/pages/tasks_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize & load durable local persistence
  await LocalDatabase.instance.loadFromDisk();

  // 2. Initialize default MVP template tasks if storage is fresh
  LocalDatabase.instance.initializeDefaultTemplates();

  // 3. Reconcile persisted active alarms with Android OS schedules
  final alarmService = AlarmService(LocalDatabase.instance);
  await alarmService.reconcilePersistedAlarmsOnStartup();

  // 4. Check for cold-start intent route (e.g. from alarm / notification)
  final initialRoute = await NativeAlarmService.getInitialRoute();

  runApp(HabitatApp(initialRoute: initialRoute));
}

class HabitatApp extends StatelessWidget {
  final String? initialRoute;

  const HabitatApp({super.key, this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitat',
      debugShowCheckedModeBanner: false,
      theme: HabitatTheme.darkTheme,
      home: HabitatHomeScreen(initialRoute: initialRoute),
    );
  }
}

class HabitatHomeScreen extends StatefulWidget {
  final String? initialRoute;

  const HabitatHomeScreen({super.key, this.initialRoute});

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
