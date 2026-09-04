// Habitat Achievements Gallery Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../application/achievement_controller.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/services/achievement_service.dart';
import '../widgets/achievement_card.dart';

class AchievementsPage extends StatefulWidget {
  final AchievementController? controller;

  const AchievementsPage({super.key, this.controller});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  late final AchievementController _controller;
  bool _internalController = false;

  final List<String> _filters = [
    'ALL',
    'UNLOCKED',
    'LOCKED',
    'TASKS',
    'STREAKS',
    'HEALTH'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      final db = LocalDatabase.instance;
      _controller = AchievementController(
        achievementService: AchievementService(ProgressRepository(db)),
        database: db,
      );
      _internalController = true;
    }
  }

  @override
  void dispose() {
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final achievements = _controller.filteredAchievements;
        final all = _controller.allAchievements;
        final unlockedCount = all.where((a) => a.isUnlocked).length;

        return Scaffold(
          backgroundColor: HabitatTheme.background,
          appBar: AppBar(
            title: const Text('ACHIEVEMENTS GALLERY'),
            backgroundColor: HabitatTheme.background,
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Unlocked Counter Banner
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: HabitatTheme.surfacePrimary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: HabitatTheme.growthGreen.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: HabitatTheme.habitatGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.emoji_events,
                            color: HabitatTheme.growthGreen, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$unlockedCount of ${all.length} Unlocked',
                            style: const TextStyle(
                              fontFamily: HabitatTheme.fontHeading,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Earn bonus growth points as you build consistency.',
                            style: TextStyle(
                              fontFamily: HabitatTheme.fontBody,
                              fontSize: 11,
                              color: HabitatTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _controller.activeFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          selectedColor: HabitatTheme.growthGreen,
                          backgroundColor: HabitatTheme.surfacePrimary,
                          labelStyle: TextStyle(
                            fontFamily: HabitatTheme.fontHeading,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color:
                                isSelected ? HabitatTheme.forest : Colors.white,
                          ),
                          onSelected: (_) => _controller.setFilter(filter),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Achievements List
                Expanded(
                  child: achievements.isEmpty
                      ? Center(
                          child: Text(
                            'No ${_controller.activeFilter} achievements.',
                            style: const TextStyle(
                                color: HabitatTheme.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 6),
                          itemCount: achievements.length,
                          itemBuilder: (context, index) {
                            return AchievementCard(
                                achievement: achievements[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
