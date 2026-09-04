// Habitat Master Progress Hub Screen (Tab 2)
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../application/progress_controller.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/services/achievement_service.dart';
import '../../domain/services/daily_summary_service.dart';
import '../../domain/services/monthly_summary_service.dart';
import '../../domain/services/progress_service.dart';
import '../../domain/services/streak_service.dart';
import '../../domain/services/weekly_summary_service.dart';
import '../widgets/achievement_card.dart';
import '../widgets/daily_graph.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/streak_card.dart';
import '../widgets/today_progress_card.dart';
import '../widgets/weekly_graph.dart';
import 'achievements_page.dart';
import 'daily_progress_page.dart';
import 'monthly_progress_page.dart';
import 'streak_page.dart';
import 'weekly_progress_page.dart';

class ProgressPage extends StatefulWidget {
  final ProgressController? controller;

  const ProgressPage({super.key, this.controller});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  late final ProgressController _controller;
  late final MonthlySummaryService _monthlyService;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    final db = LocalDatabase.instance;
    final repo = ProgressRepository(db);
    final daily = DailySummaryService(repo);
    final weekly = WeeklySummaryService(daily);
    final streak = StreakService(repo);
    final achievements = AchievementService(repo);
    _monthlyService = MonthlySummaryService(weekly);

    final progressService = ProgressService(
      repository: repo,
      dailyService: daily,
      weeklyService: weekly,
      streakService: streak,
      achievementService: achievements,
    );

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = ProgressController(
        progressService: progressService,
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
        final overview = _controller.overview;
        final monthly = _monthlyService.getMonthlySummary();

        return Scaffold(
          backgroundColor: HabitatTheme.background,
          appBar: AppBar(
            title: const Text('DISCIPLINE PROGRESS'),
            backgroundColor: HabitatTheme.background,
            actions: [
              IconButton(
                icon: const Icon(Icons.emoji_events_outlined,
                    color: Colors.white),
                tooltip: 'Achievements Gallery',
                onPressed: _openAchievementsPage,
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Timeframe Scope Selector
                  DateRangeSelector(
                    selectedTimeframe: _controller.selectedTimeframe,
                    onTimeframeChanged: (tf) => _controller.setTimeframe(tf),
                  ),
                  const SizedBox(height: 18),

                  // 2. Main Progress Centerpiece (Scope-dependent)
                  if (_controller.selectedTimeframe == 'TODAY') ...[
                    TodayProgressCard(
                      summary: overview.today,
                      onTapDetails: () => _openDailyPage(overview.today.date),
                    ),
                    const SizedBox(height: 18),
                    DailyGraph(
                      weekSummary: overview.thisWeek,
                      onSelectDay: (day) => _openDailyPage(day.date),
                    ),
                  ] else if (_controller.selectedTimeframe == 'WEEK') ...[
                    DailyGraph(
                      weekSummary: overview.thisWeek,
                      onSelectDay: (day) => _openDailyPage(day.date),
                    ),
                    const SizedBox(height: 18),
                    _buildWeeklySummaryBanner(overview.thisWeek),
                  ] else ...[
                    WeeklyGraph(monthlySummary: monthly),
                  ],
                  const SizedBox(height: 18),

                  // 3. Streak Hero Card
                  StreakCard(
                    streak: overview.streak,
                    onOpenDetails: _openStreakPage,
                  ),
                  const SizedBox(height: 24),

                  // 4. Milestone Achievements Preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'UNLOCKED ACHIEVEMENTS',
                        style: TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: HabitatTheme.youngLeaf,
                        ),
                      ),
                      InkWell(
                        onTap: _openAchievementsPage,
                        child: Text(
                          '${overview.unlockedAchievementsCount} / ${overview.totalAchievementsCount} View All →',
                          style: const TextStyle(
                            fontFamily: HabitatTheme.fontHeading,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: HabitatTheme.growthGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ...overview.achievements.take(2).map((ach) {
                    return AchievementCard(
                      achievement: ach,
                      onTap: _openAchievementsPage,
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklySummaryBanner(dynamic week) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HabitatTheme.surfaceBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBannerMetric('Total Done', '${week.totalCompleted} Actions',
              HabitatTheme.growthGreen),
          _buildBannerMetric('Best Day', week.bestDay, Colors.white),
          _buildBannerMetric(
              'Lowest Day', week.lowestDay, HabitatTheme.textMuted),
        ],
      ),
    );
  }

  Widget _buildBannerMetric(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: HabitatTheme.fontBody,
                fontSize: 11,
                color: HabitatTheme.textSecondary)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: valueColor)),
      ],
    );
  }

  void _openDailyPage(DateTime date) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DailyProgressPage(date: date)),
    );
  }

  void _openStreakPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StreakPage()),
    );
  }

  void _openAchievementsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AchievementsPage()),
    );
  }
}
