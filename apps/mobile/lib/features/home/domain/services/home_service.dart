// Habitat Home Service & Orchestrator
import '../../../../database/local_database.dart';
import '../models/home_state_model.dart';

/// Composes Home-specific view data from local domain records and services.
/// Home is a consumer and orchestrator of domain summaries, maintaining
/// a clean separation of concerns and local-first architecture.
class HomeService {
  final LocalDatabase _database;

  HomeService(this._database);

  HomeStateModel load({DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    final user = _database.getOrCreateProfile();
    final allTasks = _database.getAllTasks();
    final activeTasks = allTasks.where((task) => task.active).toList();

    final attemptsToday = _database
        .getAllAttempts()
        .where((attempt) => _sameDay(attempt.triggeredAt, timestamp))
        .toList();

    final completedTaskIds = attemptsToday
        .where((attempt) => attempt.status == 'COMPLETED')
        .map((attempt) => attempt.taskId)
        .toSet();

    final missedTaskIds = attemptsToday
        .where((attempt) => attempt.status == 'FAILED')
        .map((attempt) => attempt.taskId)
        .toSet();

    final currentAction = _resolveCurrentAction(activeTasks, attemptsToday);

    final waterEntries = _database.getWaterEntriesForDay(timestamp);
    final mealEntries = _database.getMealEntriesForDay(timestamp);
    final napEntries = _database.getNapEntriesForDay(timestamp);
    final isNapRunning = napEntries.any((entry) => entry.isRunning);
    final totalNapMinutes =
        napEntries.fold(0, (total, entry) => total + entry.durationMinutes);

    final streak = _database.getStreak();
    final stageMotto = _resolveStageMotto(streak.currentStreak);

    final alarms = _database.getAllAlarms();
    final enabledAlarmsCount = alarms.where((a) => a.enabled).length;

    return HomeStateModel(
      user: HomeUserSummary(
        displayName: user.displayName,
        date: timestamp,
        contextMotto: 'Build today\'s habitat. One action at a time.',
      ),
      currentAction: currentAction,
      upcomingTasks: activeTasks
          .where((task) =>
              task.id != currentAction?.taskId &&
              !completedTaskIds.contains(task.id))
          .take(3)
          .map((task) => HomeTaskPreview(
                id: task.id,
                title: task.title,
                detail: '${task.category} • ${task.taskType} proof required',
                category: task.category,
                taskType: task.taskType,
              ))
          .toList(),
      dailyProgress: DailyProgressSummary(
        totalTasks: activeTasks.length,
        completedTasks: completedTaskIds.length,
        missedTasks: missedTaskIds.length,
      ),
      health: HealthSummary(
        waterMilliliters:
            waterEntries.fold(0, (total, entry) => total + entry.milliliters),
        waterTargetMilliliters: 2000,
        mealsLogged: mealEntries.length,
        mealTarget: 4,
        napMinutes: totalNapMinutes,
        napRunning: isNapRunning,
      ),
      streak: StreakSummary(
        currentStreak: streak.currentStreak,
        bestStreak: streak.longestStreak,
        stageMotto: stageMotto,
      ),
      notifications: NotificationSummary(
        enabledAlarmCount: enabledAlarmsCount,
        hasUnreadAlerts: false,
      ),
    );
  }

  CurrentAction? _resolveCurrentAction(
      List<LocalTask> tasks, List<LocalTaskAttempt> attemptsToday) {
    if (tasks.isEmpty) return null;

    // 1. Check for active or in-progress attempt first (highest priority)
    LocalTaskAttempt? activeAttempt;
    for (final attempt in attemptsToday) {
      if (const {'RINGING', 'AWAITING_ACTION', 'RETRY'}
          .contains(attempt.status)) {
        activeAttempt = attempt;
        break;
      }
    }

    if (activeAttempt != null) {
      final task = _database.getTask(activeAttempt.taskId);
      if (task != null) {
        final isRetry = activeAttempt.status == 'RETRY';
        return CurrentAction(
          taskId: task.id,
          title: task.title,
          detail: isRetry
              ? 'Verification needs another attempt. Review instructions and retry.'
              : 'Action in progress. Complete verification when ready.',
          status: isRetry
              ? CurrentActionStatus.retryRequired
              : CurrentActionStatus.active,
          scheduledFor: activeAttempt.triggeredAt,
          category: task.category,
          taskType: task.taskType,
        );
      }
    }

    // 2. Filter completed and missed tasks
    final completedTaskIds = attemptsToday
        .where((a) => a.status == 'COMPLETED')
        .map((a) => a.taskId)
        .toSet();

    final remainingTasks =
        tasks.where((t) => !completedTaskIds.contains(t.id)).toList();

    // 3. If all tasks completed
    if (remainingTasks.isEmpty) {
      final lastTask = tasks.last;
      return CurrentAction(
        taskId: lastTask.id,
        title: 'All Disciplines Completed',
        detail: 'Outstanding consistency today. Rest and recover for tomorrow.',
        status: CurrentActionStatus.completed,
        category: 'DAILY_GOAL',
        taskType: 'SUMMARY',
      );
    }

    // 4. Next pending task is ready
    final nextTask = remainingTasks.first;
    return CurrentAction(
      taskId: nextTask.id,
      title: nextTask.title,
      detail: '${nextTask.category} • ${nextTask.taskType} proof required',
      status: CurrentActionStatus.ready,
      category: nextTask.category,
      taskType: nextTask.taskType,
    );
  }

  String _resolveStageMotto(int streakDays) {
    if (streakDays >= 21) return 'Ancient Forest Stage';
    if (streakDays >= 7) return 'Canopy Stage';
    if (streakDays >= 3) return 'Sapling Stage';
    return 'Sprout Stage';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
