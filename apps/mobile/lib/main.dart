// Habitat Flutter Application Entry Point
import 'package:flutter/material.dart';
import 'core/theme/habitat_theme.dart';
import 'features/missions/presentation/active_mission_screen.dart';
import 'features/tasks/presentation/task_catalog_screen.dart';
import 'features/alarms/presentation/alarm_list_screen.dart';
import 'database/local_database.dart';

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
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      body: _buildCurrentTab(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: HabitatTheme.surfaceBorder, width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: HabitatTheme.surfacePrimary,
          selectedItemColor: HabitatTheme.growthGreen,
          unselectedItemColor: HabitatTheme.textMuted,
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          onTap: (idx) => setState(() => _selectedIndex = idx),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              activeIcon: Icon(Icons.check_circle),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none),
              activeIcon: Icon(Icons.notifications),
              label: 'Reminders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label: 'Proof',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_fire_department_outlined),
              activeIcon: Icon(Icons.local_fire_department),
              label: 'Streaks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up),
              activeIcon: Icon(Icons.trending_up),
              label: 'Growth',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'You',
            ),
          ],
        ),
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
        return _buildStreaksDeck();
      case 4:
        return _buildGrowthDashboard();
      case 5:
        return _buildProfileDeck();
      default:
        return _buildTodayDeck();
    }
  }

  Widget _buildTodayDeck() {
    final streak = LocalDatabase.instance.getStreak();
    final totalXp = LocalDatabase.instance.getTotalXP();
    final tasks = LocalDatabase.instance.getAllTasks();

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: HabitatTheme.forestGreen,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: HabitatTheme.growthGreen, width: 1),
              ),
              child: const Text(
                'H',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: HabitatTheme.offWhite,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'HABITAT',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: HabitatTheme.growthGreen),
            onPressed: _triggerDemoAlarm,
            tooltip: 'Demo Action Trigger',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tagline Header
            const Center(
              child: Text(
                'Build the life you want to live.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: HabitatTheme.sageGreen,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Streak & Progress HUD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: HabitatTheme.surfaceBorder),
                boxShadow: [
                  BoxStyle(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHudItem('CONSISTENCY', '${streak.currentStreak} DAYS', Icons.local_fire_department, HabitatTheme.growthGreen),
                  Container(width: 1, height: 40, color: HabitatTheme.surfaceBorder),
                  _buildHudItem('GROWTH POINTS', '$totalXp XP', Icons.trending_up, HabitatTheme.sageGreen),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Queue Header
            const Text(
              "TODAY'S ACTIONS",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: HabitatTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Task List or Encouraging Empty State
            if (tasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: HabitatTheme.surfacePrimary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HabitatTheme.surfaceBorder),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.spa_outlined, color: HabitatTheme.sageGreen, size: 36),
                    SizedBox(height: 10),
                    Text(
                      'Your habitat starts with one action.',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Create your first daily practice to begin your journey.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: HabitatTheme.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ...tasks.map((task) => _buildTaskCard(task)),

            const SizedBox(height: 32),

            // Official Brand Bottom Motto
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: HabitatTheme.deepForest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: HabitatTheme.surfaceBorder, width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco, size: 14, color: HabitatTheme.growthGreen),
                    SizedBox(width: 8),
                    Text(
                      'YOUR HABITAT. YOUR ACTIONS. YOUR GROWTH.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: HabitatTheme.sageGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHudItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold, color: HabitatTheme.textMuted, letterSpacing: 1.0)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
      ],
    );
  }

  Widget _buildTaskCard(LocalTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HabitatTheme.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: HabitatTheme.forestGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              task.taskType == 'VIDEO' ? Icons.videocam : Icons.camera_alt,
              color: HabitatTheme.growthGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.category,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: HabitatTheme.sageGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _startTask(task),
            style: ElevatedButton.styleFrom(
              backgroundColor: HabitatTheme.growthGreen,
              foregroundColor: HabitatTheme.deepForest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Action', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStreaksDeck() {
    final streak = LocalDatabase.instance.getStreak();
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(title: const Text('STREAKS & CONSISTENCY')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_fire_department, size: 72, color: HabitatTheme.growthGreen),
            const SizedBox(height: 16),
            Text('${streak.currentStreak} Days', style: const TextStyle(fontFamily: 'Poppins', fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Longest Streak: ${0} Days', style: TextStyle(fontFamily: 'Inter', color: HabitatTheme.sageGreen)),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthDashboard() {
    final xp = LocalDatabase.instance.getTotalXP();
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(title: const Text('GROWTH DASHBOARD')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.trending_up, size: 72, color: HabitatTheme.sageGreen),
            const SizedBox(height: 16),
            Text('$xp Growth Points', style: const TextStyle(fontFamily: 'Poppins', fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Your habitat evolves with every completed practice.', style: TextStyle(fontFamily: 'Inter', color: HabitatTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDeck() {
    final user = LocalDatabase.instance.getOrCreateProfile();
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(title: const Text('YOU & SETTINGS')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: HabitatTheme.forestGreen,
                  child: Icon(Icons.person, size: 36, color: HabitatTheme.growthGreen),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('Habitat Explorer', style: TextStyle(fontFamily: 'Inter', color: HabitatTheme.sageGreen, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text('ABOUT HABITAT', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: HabitatTheme.textMuted)),
            const SizedBox(height: 12),
            const Text('Habitat v1.0.0\nBuild the life you want to live.', style: TextStyle(fontFamily: 'Inter', color: HabitatTheme.textSecondary, height: 1.5)),
          ],
        ),
      ),
    );
  }

  void _triggerDemoAlarm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ActiveMissionScreen(
          missionId: 'demo-action-001',
          taskTitle: '15 Morning Pushups',
          missionType: 'EXERCISE',
          verificationType: 'VIDEO',
        ),
      ),
    );
  }

  void _startTask(LocalTask task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveMissionScreen(
          missionId: 'action-${task.id}',
          taskTitle: task.title,
          missionType: task.category,
          verificationType: task.taskType,
        ),
      ),
    );
  }
}

class BoxStyle {
  final Color color;
  final double blurRadius;
  final Offset offset;
  const BoxStyle({required this.color, required this.blurRadius, required this.offset});
}
