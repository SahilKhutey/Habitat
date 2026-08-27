// Habitat Flutter Application Entry Point (Phase 01-05 Integrated)
import 'package:flutter/material.dart';
import 'core/theme/habitat_theme.dart';
import 'features/missions/presentation/active_mission_screen.dart';
import 'features/tasks/presentation/task_catalog_screen.dart';
import 'features/alarms/presentation/alarm_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HabitatApp());
}

class HabitatApp extends StatelessWidget {
  const HabitatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitat Discipline',
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
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      body: _buildCurrentTab(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: HabitatTheme.surfacePrimary,
        selectedItemColor: HabitatTheme.amberFocus,
        unselectedItemColor: HabitatTheme.textMuted,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (idx) => setState(() => _selectedIndex = idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Alarms'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Catalog'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Progress'),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return _buildTodayDeck();
      case 1:
        return const AlarmListScreen();
      case 2:
        return const TaskCatalogScreen();
      case 3:
        return _buildProgressDashboard();
      default:
        return _buildTodayDeck();
    }
  }

  Widget _buildTodayDeck() {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('HABITAT DISCIPLINE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: HabitatTheme.amberFocus),
            onPressed: _triggerDemoAlarm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Streak & Resistance Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: HabitatTheme.surfaceBorder),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🔥 12-DAY STREAK', style: TextStyle(color: HabitatTheme.crimsonAlert, fontWeight: FontWeight.w900, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Discipline Score: 85/100', style: TextStyle(color: HabitatTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('⚡ 2,450 XP', style: TextStyle(color: HabitatTheme.amberFocus, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Avg Resistance: 1.8m', style: TextStyle(color: HabitatTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "TODAY'S MISSIONS",
              style: TextStyle(color: HabitatTheme.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12),
            ),
            const SizedBox(height: 12),

            // Mission Cards
            _buildMissionCard(
              time: '07:00 AM',
              title: 'Make Your Bed',
              category: 'Morning Order',
              status: 'COMPLETED',
              isDone: true,
            ),
            _buildMissionCard(
              time: '08:30 AM',
              title: '10 Morning Push-Ups',
              category: 'Physical Readiness',
              status: 'ACTIVE NOW',
              isDone: false,
              isNext: true,
              onTap: _triggerDemoAlarm,
            ),
            _buildMissionCard(
              time: '10:30 PM',
              title: 'Prepare Tomorrow Clothes',
              category: 'Living Space Order',
              status: 'PENDING',
              isDone: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard({
    required String time,
    required String title,
    required String category,
    required String status,
    required bool isDone,
    bool isNext = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isNext ? HabitatTheme.surfaceSecondary : HabitatTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNext ? HabitatTheme.amberFocus : HabitatTheme.surfaceBorder,
            width: isNext ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isDone ? Icons.check_circle : (isNext ? Icons.play_circle_fill : Icons.schedule),
              color: isDone ? HabitatTheme.emeraldVictory : (isNext ? HabitatTheme.amberFocus : HabitatTheme.textMuted),
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(time, style: TextStyle(color: isNext ? HabitatTheme.amberFocus : HabitatTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(title, style: const TextStyle(color: HabitatTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(category, style: const TextStyle(color: HabitatTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            if (isNext)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: HabitatTheme.crimsonAlert,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('TRIGGER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDashboard() {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(title: const Text('PROGRESS & RESISTANCE')),
      body: const Center(
        child: Text('Weekly Resistance Heatmap & XP Ledger Analytics', style: TextStyle(color: HabitatTheme.textSecondary)),
      ),
    );
  }

  void _triggerDemoAlarm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ActiveMissionScreen(
          missionId: 'demo-mission-1',
          taskTitle: '10 Morning Push-Ups',
          taskCategory: 'physical',
          proofType: 'VIDEO',
          instructions: [
            'Prop phone up 5-6 feet away in clear view',
            'Complete 10 strict chest-to-floor push-ups',
            'Submit proof recording',
          ],
          attemptIndex: 1,
        ),
      ),
    );
  }
}
