// Task Catalog & Category Browser Screen
import 'package:flutter/material.dart';
import '../../../core/theme/habitat_theme.dart';
import 'task_detail_screen.dart';
import 'create_custom_task_screen.dart';

class TaskCatalogScreen extends StatefulWidget {
  const TaskCatalogScreen({super.key});

  @override
  State<TaskCatalogScreen> createState() => _TaskCatalogScreenState();
}

class _TaskCatalogScreenState extends State<TaskCatalogScreen> {
  String _selectedCategory = 'ALL';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _tasks = [
    {
      'id': 't1',
      'title': 'Make Your Bed',
      'category': 'morning',
      'difficulty': 'EASY',
      'proofType': 'PHOTO',
      'baseXp': 50,
      'duration': '1 min',
      'icon': Icons.bed,
      'instructions': [
        'Step out of bed completely',
        'Smooth sheets and straighten quilt',
        'Snap photo of completed bed'
      ],
      'description':
          'Smooth sheets flat and align pillows to establish immediate order.',
    },
    {
      'id': 't2',
      'title': '10 Morning Push-Ups',
      'category': 'physical',
      'difficulty': 'HARD',
      'proofType': 'VIDEO',
      'baseXp': 80,
      'duration': '30 sec',
      'icon': Icons.fitness_center,
      'instructions': [
        'Prop phone up 5-6ft away',
        'Perform 10 full chest-to-floor pushups',
        'Submit 15s video recording'
      ],
      'description': 'Elevate heart rate and activate neuromuscular systems.',
    },
    {
      'id': 't3',
      'title': 'Brush Teeth (2 Minutes)',
      'category': 'personal',
      'difficulty': 'EASY',
      'proofType': 'VIDEO',
      'baseXp': 60,
      'duration': '2 min',
      'icon': Icons.clean_hands,
      'instructions': [
        'Stand at bathroom sink',
        'Record short 10s check-in while brushing thoroughly'
      ],
      'description':
          'Oral hygiene routine to signal alertness to your nervous system.',
    },
    {
      'id': 't4',
      'title': 'Drink 500ml Water',
      'category': 'morning',
      'difficulty': 'EASY',
      'proofType': 'PHOTO',
      'baseXp': 40,
      'duration': '45 sec',
      'icon': Icons.water_drop,
      'instructions': [
        'Pour 500ml water into glass',
        'Drink full glass',
        'Snap photo of empty glass at counter'
      ],
      'description':
          'Hydrate immediately upon waking to kickstart cellular metabolism.',
    },
    {
      'id': 't5',
      'title': 'Morning Sunlight View',
      'category': 'morning',
      'difficulty': 'MEDIUM',
      'proofType': 'PHOTO',
      'baseXp': 75,
      'duration': '3 min',
      'icon': Icons.wb_sunny,
      'instructions': [
        'Step outside or to open window',
        'Snap photo of outdoor sky/horizon'
      ],
      'description':
          'Natural outdoor photons into eyes to trigger the cortisol awakening response.',
    },
    {
      'id': 't6',
      'title': 'Clear Workspace',
      'category': 'environment',
      'difficulty': 'EASY',
      'proofType': 'PHOTO',
      'baseXp': 50,
      'duration': '2 min',
      'icon': Icons.table_restaurant,
      'instructions': [
        'Remove clutter and trash',
        'Straighten keyboard and notepad',
        'Snap overhead photo'
      ],
      'description':
          'Remove clutter and create an organized surface for focused output.',
    },
    {
      'id': 't7',
      'title': '2-Minute Outdoor Walk',
      'category': 'physical',
      'difficulty': 'MEDIUM',
      'proofType': 'VIDEO',
      'baseXp': 70,
      'duration': '2 min',
      'icon': Icons.directions_walk,
      'instructions': [
        'Step outside or down hallway',
        'Record brief clip as you take a brisk 2-min stride'
      ],
      'description':
          'Gentle aerobic locomotion to stimulate lymphatic flow and alertness.',
    },
    {
      'id': 't8',
      'title': 'Read 2 Physical Pages',
      'category': 'mind',
      'difficulty': 'MEDIUM',
      'proofType': 'PHOTO',
      'baseXp': 60,
      'duration': '3 min',
      'icon': Icons.menu_book,
      'instructions': [
        'Open physical book',
        'Read 2 full pages attentively',
        'Snap photo of open book'
      ],
      'description': 'Engage cognitive focus on non-screen physical text.',
    },
    {
      'id': 't9',
      'title': '30-Second Full Body Stretch',
      'category': 'physical',
      'difficulty': 'EASY',
      'proofType': 'VIDEO',
      'baseXp': 50,
      'duration': '30 sec',
      'icon': Icons.self_improvement,
      'instructions': [
        'Set camera to view full torso',
        'Perform overhead extension and hamstring stretch'
      ],
      'description': 'Decompress spinal column and open thoracic posture.',
    },
    {
      'id': 't10',
      'title': 'Night Prep: Tomorrow Clothes',
      'category': 'environment',
      'difficulty': 'EASY',
      'proofType': 'PHOTO',
      'baseXp': 45,
      'duration': '1 min',
      'icon': Icons.checkroom,
      'instructions': [
        'Select workout or workday outfit',
        'Lay out ready on chair',
        'Snap photo of setup'
      ],
      'description':
          'Evening friction-reduction ritual for frictionless next-morning execution.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _tasks.where((t) {
      final matchesCat = _selectedCategory == 'ALL' ||
          t['category'] == _selectedCategory.toLowerCase();
      final matchesSearch = t['title']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('MISSION CATALOG'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: HabitatTheme.amberFocus),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const CreateCustomTaskScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search missions (push-ups, bed, walk)...',
                prefixIcon:
                    const Icon(Icons.search, color: HabitatTheme.textSecondary),
                filled: true,
                fillColor: HabitatTheme.surfacePrimary,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: HabitatTheme.surfaceBorder),
                ),
              ),
            ),
          ),

          // 2. Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                _buildCategoryChip('ALL', 'All'),
                _buildCategoryChip('MORNING', '🌅 Morning'),
                _buildCategoryChip('PHYSICAL', '💪 Physical'),
                _buildCategoryChip('PERSONAL', '🧼 Hygiene'),
                _buildCategoryChip('MIND', '🧠 Mind'),
                _buildCategoryChip('ENVIRONMENT', '🧹 Environment'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 3. Task List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                return _buildTaskCard(task);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = key),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? HabitatTheme.amberFocus
              : HabitatTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? HabitatTheme.amberFocus
                : HabitatTheme.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : HabitatTheme.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    Color diffColor = HabitatTheme.emeraldVictory;
    if (task['difficulty'] == 'MEDIUM') diffColor = HabitatTheme.amberFocus;
    if (task['difficulty'] == 'HARD') diffColor = HabitatTheme.crimsonAlert;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
        );
      },
      child: Container(
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HabitatTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(task['icon'] as IconData,
                  color: HabitatTheme.amberFocus, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: diffColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task['difficulty'],
                          style: TextStyle(
                              color: diffColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '⏱️ ${task['duration']}',
                        style: const TextStyle(
                            color: HabitatTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task['title'],
                    style: const TextStyle(
                        color: HabitatTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${task['baseXp']} XP',
                  style: const TextStyle(
                      color: HabitatTheme.amberFocus,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                const SizedBox(height: 4),
                Icon(
                  task['proofType'] == 'VIDEO'
                      ? Icons.videocam
                      : Icons.camera_alt,
                  size: 16,
                  color: HabitatTheme.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
