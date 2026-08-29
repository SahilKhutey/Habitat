// Habitat Flutter Application Entry Point & Navigation Experience
import 'package:flutter/material.dart';
import 'core/theme/habitat_theme.dart';
import 'features/missions/presentation/active_mission_screen.dart';
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
              icon: Icon(Icons.wb_sunny_outlined),
              activeIcon: Icon(Icons.wb_sunny),
              label: 'Today',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist_rtl),
              activeIcon: Icon(Icons.checklist_rtl),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.spa_outlined),
              activeIcon: Icon(Icons.spa),
              label: 'Journey',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return _buildTodayScreen();
      case 1:
        return _buildTasksScreen();
      case 2:
        return _buildJourneyScreen();
      case 3:
        return _buildMoreScreen();
      default:
        return _buildTodayScreen();
    }
  }

  // 1. TODAY SCREEN (Heart of Habitat)
  Widget _buildTodayScreen() {
    final streak = LocalDatabase.instance.getStreak();
    final totalXp = LocalDatabase.instance.getTotalXP();
    final user = LocalDatabase.instance.getOrCreateProfile();

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: HabitatTheme.habitatGreen,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: HabitatTheme.growthGreen, width: 1),
              ),
              child: const Text(
                'H',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: HabitatTheme.habitatCream,
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
            icon: const Icon(Icons.notifications_active_outlined, color: HabitatTheme.growthGreen),
            onPressed: _openActiveAlarmScreen,
            tooltip: 'Active Reminder Screen',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Greeting & Calm Positioning
            Text(
              'Good morning, ${user.displayName}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Build today's habitat. One action at a time.",
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: HabitatTheme.youngLeaf,
              ),
            ),
            const SizedBox(height: 20),

            // Streak & Growth Points Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: HabitatTheme.surfaceBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHudItem('CONSISTENCY', '${streak.currentStreak} DAYS', Icons.local_fire_department, HabitatTheme.growthGreen),
                  Container(width: 1, height: 44, color: HabitatTheme.surfaceBorder),
                  _buildHudItem('GROWTH POINTS', '$totalXp XP', Icons.trending_up, HabitatTheme.youngLeaf),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Today's Action Timeline
            const Text(
              'TODAY',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: HabitatTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            _buildActionRow('08:00', 'Morning Exercise', '10 Push-ups', 'Ready', Icons.directions_run, true),
            _buildActionRow('09:30', 'Brush & Capture', 'Photo verification', 'Upcoming', Icons.camera_alt_outlined, false),
            _buildActionRow('18:00', 'Step Outside Walk', 'Fresh air 5 min', 'Upcoming', Icons.park_outlined, false),
            _buildActionRow('21:30', 'Read 10 Pages', 'Mind reflection', 'Upcoming', Icons.menu_book, false),

            const SizedBox(height: 32),

            // Bottom Brand Motto
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: HabitatTheme.forest,
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
                        color: HabitatTheme.youngLeaf,
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

  Widget _buildActionRow(String time, String title, String subtitle, String status, IconData icon, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isActive ? HabitatTheme.growthGreen.withOpacity(0.5) : HabitatTheme.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? HabitatTheme.habitatGreen : HabitatTheme.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isActive ? HabitatTheme.growthGreen : HabitatTheme.textSecondary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$time • $title',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: HabitatTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            ElevatedButton(
              onPressed: _openActiveAlarmScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: HabitatTheme.growthGreen,
                foregroundColor: HabitatTheme.forest,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Start', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12)),
            )
          else
            Text(
              status,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: HabitatTheme.youngLeaf, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  // 2. TASKS & STARTER ACTIONS SCREEN
  Widget _buildTasksScreen() {
    final starterActions = [
      {'num': '01', 'title': 'Step Outside', 'desc': 'Take a photo outside in sunlight.', 'type': 'PHOTO'},
      {'num': '02', 'title': 'Morning Movement', 'desc': 'Complete your chosen 10-15 pushups.', 'type': 'VIDEO'},
      {'num': '03', 'title': 'Brush & Capture', 'desc': 'Take a photo while brushing teeth.', 'type': 'PHOTO'},
      {'num': '04', 'title': 'Make Your Bed', 'desc': 'Capture your completed bed.', 'type': 'PHOTO'},
      {'num': '05', 'title': 'Drink Water', 'desc': 'Complete your morning 500ml water action.', 'type': 'PHOTO'},
      {'num': '06', 'title': 'Fresh Air', 'desc': 'Step outside for 5 minutes of stillness.', 'type': 'PHOTO'},
      {'num': '07', 'title': 'Tidy One Space', 'desc': 'Clean and organize one small work area.', 'type': 'PHOTO'},
      {'num': '08', 'title': 'Read 10 Pages', 'desc': 'Read for 10 minutes from a book.', 'type': 'PHOTO'},
      {'num': '09', 'title': 'Daily Walk', 'desc': 'Complete your daily physical walk.', 'type': 'PHOTO'},
      {'num': '10', 'title': 'Personal Action', 'desc': 'Create your own custom practice.', 'type': 'CUSTOM'},
    ];

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(title: const Text('STARTER ACTIONS')),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: starterActions.length,
        itemBuilder: (context, index) {
          final item = starterActions[index];
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
                Text(
                  item['num']!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: HabitatTheme.youngLeaf,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']!,
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['desc']!,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: HabitatTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  item['type'] == 'VIDEO' ? Icons.videocam_outlined : Icons.camera_alt_outlined,
                  color: HabitatTheme.growthGreen,
                  size: 20,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 3. JOURNEY & HABITAT GROWTH SCREEN
  Widget _buildJourneyScreen() {
    final streak = LocalDatabase.instance.getStreak();
    final xp = LocalDatabase.instance.getTotalXP();

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(title: const Text('JOURNEY & GROWTH')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: HabitatTheme.surfaceBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.eco, size: 64, color: HabitatTheme.growthGreen),
                  const SizedBox(height: 12),
                  const Text(
                    'YOUR HABITAT STAGE: SPROUT',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2, color: HabitatTheme.youngLeaf),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${streak.currentStreak} Days Consistent',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Keep showing up to evolve into a full Forest.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: HabitatTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: HabitatTheme.surfaceBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHudItem('TOTAL XP', '$xp Growth Points', Icons.trending_up, HabitatTheme.growthGreen),
                  _buildHudItem('WEEKLY GOAL', '7 / 7 Actions', Icons.verified_outlined, HabitatTheme.youngLeaf),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. MORE DOMAINS (Health, Journal & Settings)
  Widget _buildMoreScreen() {
    final user = LocalDatabase.instance.getOrCreateProfile();
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(title: const Text('MORE DOMAINS')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HabitatTheme.surfacePrimary,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: HabitatTheme.surfaceBorder),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: HabitatTheme.habitatGreen,
                  child: Icon(Icons.person, color: HabitatTheme.growthGreen, size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    const Text('Habitat Explorer', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: HabitatTheme.youngLeaf)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Domains List
          _buildMoreTile(Icons.water_drop_outlined, 'Health & Hydration', 'Water, movement & sleep metrics'),
          _buildMoreTile(Icons.edit_note, 'Daily Reflection Journal', 'How was today? Mood & energy'),
          _buildMoreTile(Icons.file_download_outlined, 'Export My Data', 'Local JSON backup & diagnostics'),
          _buildMoreTile(Icons.feedback_outlined, 'Send Feedback', 'Suggestions, bug reports & ratings'),
          _buildMoreTile(Icons.info_outline, 'About Habitat', 'v1.0.0 • Build the life you want to live.'),
        ],
      ),
    );
  }

  Widget _buildMoreTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HabitatTheme.surfaceBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: HabitatTheme.growthGreen),
        title: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: HabitatTheme.textSecondary)),
        trailing: const Icon(Icons.chevron_right, color: HabitatTheme.textMuted),
        onTap: () {},
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
        Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
      ],
    );
  }

  void _openActiveAlarmScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ActiveMissionScreen(
          missionId: 'action-morning-001',
          taskTitle: '10 Morning Push-ups',
          missionType: 'EXERCISE',
          verificationType: 'VIDEO',
        ),
      ),
    );
  }
}
