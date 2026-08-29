// Habitat Master Progress Orchestrator Service
import '../models/progress_overview_model.dart';
import '../repositories/progress_repository.dart';
import 'achievement_service.dart';
import 'daily_summary_service.dart';
import 'streak_service.dart';
import 'weekly_summary_service.dart';

class ProgressService {
  final ProgressRepository _repository;
  final DailySummaryService _dailyService;
  final WeeklySummaryService _weeklyService;
  final StreakService _streakService;
  final AchievementService _achievementService;

  ProgressService({
    required ProgressRepository repository,
    required DailySummaryService dailyService,
    required WeeklySummaryService weeklyService,
    required StreakService streakService,
    required AchievementService achievementService,
  })  : _repository = repository,
        _dailyService = dailyService,
        _weeklyService = weeklyService,
        _streakService = streakService,
        _achievementService = achievementService;

  ProgressOverviewModel getOverview() {
    _achievementService.evaluateAndUnlock();

    final today = _dailyService.getDailySummary(DateTime.now());
    final thisWeek = _weeklyService.getWeeklySummary();
    final streak = _streakService.getStreak();
    final achievements = _achievementService.getAllAchievements();
    final totalXp = _repository.getTotalXp();

    return ProgressOverviewModel(
      today: today,
      thisWeek: thisWeek,
      streak: streak,
      achievements: achievements,
      totalXp: totalXp,
    );
  }
}
