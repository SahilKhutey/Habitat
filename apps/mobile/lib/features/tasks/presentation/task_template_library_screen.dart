// Starter Task Template Library Screen
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class TaskTemplateLibraryScreen extends StatelessWidget {
  const TaskTemplateLibraryScreen({super.key});

  final List<Map<String, dynamic>> _templates = const [
    {
      'id': 'tpl-morning-outside',
      'name': 'Morning Outside Photo',
      'category': 'ENVIRONMENT',
      'proofType': 'PHOTO',
      'baseXp': 20,
      'difficulty': 1,
      'icon': Icons.wb_sunny,
      'desc': 'Step outside to trigger the cortisol awakening response.'
    },
    {
      'id': 'tpl-pushups-10',
      'name': '10 Morning Push-Ups',
      'category': 'PHYSICAL',
      'proofType': 'VIDEO',
      'baseXp': 30,
      'difficulty': 2,
      'icon': Icons.fitness_center,
      'desc': 'Activate neuromuscular systems with 10 strict repetitions.'
    },
    {
      'id': 'tpl-brush-teeth',
      'name': 'Brush Teeth & Oral Care',
      'category': 'HEALTH',
      'proofType': 'PHOTO',
      'baseXp': 15,
      'difficulty': 1,
      'icon': Icons.clean_hands,
      'desc': 'Oral hygiene routine signaling metabolic alertness.'
    },
    {
      'id': 'tpl-drink-water',
      'name': 'Drink 500ml Water',
      'category': 'HEALTH',
      'proofType': 'PHOTO',
      'baseXp': 10,
      'difficulty': 1,
      'icon': Icons.water_drop,
      'desc': 'Rehydrate immediately upon waking.'
    },
    {
      'id': 'tpl-make-bed',
      'name': 'Make Your Bed',
      'category': 'MORNING',
      'proofType': 'PHOTO',
      'baseXp': 15,
      'difficulty': 1,
      'icon': Icons.bed,
      'desc': 'Establish immediate physical order in sleeping quarters.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('STARTER TEMPLATES'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.xl),
        itemCount: _templates.length,
        itemBuilder: (ctx, idx) {
          final tpl = _templates[idx];
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: AppCard(
              onTap: () {
                Navigator.of(context)
                    .pushNamed('/tasks/create-wizard', arguments: tpl);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(tpl['icon'] as IconData,
                              color: AppColors.amberFocus, size: 22),
                          const SizedBox(width: AppSpacing.sm),
                          Text(tpl['name'] as String,
                              style: AppTypography.titleLarge),
                        ],
                      ),
                      Text('+${tpl['baseXp']} XP',
                          style: const TextStyle(
                              color: AppColors.emeraldVictory,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(tpl['desc'] as String, style: AppTypography.bodySmall),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: AppRadii.radiusSmall,
                        ),
                        child: Text('${tpl['category']} • ${tpl['proofType']}',
                            style: AppTypography.labelSmall),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
