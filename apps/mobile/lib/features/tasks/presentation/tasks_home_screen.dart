// Tactical Tasks Home Screen with Segmented Tabs
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class TasksHomeScreen extends StatefulWidget {
  const TasksHomeScreen({super.key});

  @override
  State<TasksHomeScreen> createState() => _TasksHomeScreenState();
}

class _TasksHomeScreenState extends State<TasksHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _activeTasks = [
    {
      'id': '1',
      'name': '10 Morning Push-Ups',
      'category': 'PHYSICAL',
      'proofType': 'VIDEO',
      'difficulty': 2,
      'xpReward': 30,
      'status': 'ACTIVE',
      'icon': Icons.fitness_center,
    },
    {
      'id': '2',
      'name': 'Morning Outside Photo',
      'category': 'ENVIRONMENT',
      'proofType': 'PHOTO',
      'difficulty': 1,
      'xpReward': 20,
      'status': 'ACTIVE',
      'icon': Icons.wb_sunny,
    },
    {
      'id': '3',
      'name': 'Make Your Bed',
      'category': 'MORNING',
      'proofType': 'PHOTO',
      'difficulty': 1,
      'xpReward': 15,
      'status': 'ACTIVE',
      'icon': Icons.bed,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('DISCIPLINE TASKS'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.amberFocus,
          labelColor: AppColors.amberFocus,
          unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          tabs: const [
            Tab(text: 'ACTIVE (3)'),
            Tab(text: 'PAUSED (0)'),
            Tab(text: 'ARCHIVE (0)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Active Tasks Tab
          ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.xl),
            itemCount: _activeTasks.length,
            itemBuilder: (ctx, idx) {
              final task = _activeTasks[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: AppCard(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening ${task['name']} details...')),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.amberFocusSubtle,
                          borderRadius: AppRadii.radiusMedium,
                        ),
                        child: Icon(task['icon'] as IconData, color: AppColors.amberFocus, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task['name'] as String, style: AppTypography.titleLarge),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              '${task['category']} • ${task['proofType']} PROOF',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+${task['xpReward']} XP',
                        style: const TextStyle(
                          color: AppColors.emeraldVictory,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Paused Tab
          const EmptyStateWidget(
            title: 'NO PAUSED TASKS',
            message: 'Paused discipline tasks stop scheduling future wake-up alarms.',
            icon: Icons.pause_circle_outline,
          ),

          // 3. Archived Tab
          const EmptyStateWidget(
            title: 'NO ARCHIVED TASKS',
            message: 'Archived tasks retain all past mission audit logs forever.',
            icon: Icons.archive_outlined,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.amberFocus,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('ADD TASK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        onPressed: () {
          Navigator.of(context).pushNamed('/tasks/templates');
        },
      ),
    );
  }
}
