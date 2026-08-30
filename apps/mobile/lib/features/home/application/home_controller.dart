// Habitat Master Home Aggregation Application Controller
import 'package:flutter/foundation.dart';
import '../../../../database/local_database.dart';
import '../../alarms/domain/services/alarm_scheduler.dart';
import '../../gamification/domain/services/progression_engine.dart';
import '../../health/domain/services/water_service.dart';
import '../../tasks/domain/services/task_lifecycle_service.dart';

@immutable
class HomeState {
  final int tasksCompleted;
  final int tasksTotal;
  final HabitatAlarm? nextAlarm;
  final LocalTask? activeTask;
  final int waterConsumedMl;
  final int waterTargetMl;
  final int streakDays;
  final int userLevel;
  final String disciplineTitle;

  const HomeState({
    required this.tasksCompleted,
    required this.tasksTotal,
    this.nextAlarm,
    this.activeTask,
    required this.waterConsumedMl,
    required this.waterTargetMl,
    required this.streakDays,
    required this.userLevel,
    required this.disciplineTitle,
  });

  double get completionRate =>
      tasksTotal <= 0 ? 0.0 : (tasksCompleted / tasksTotal).clamp(0.0, 1.0);

  double get waterProgress =>
      waterTargetMl <= 0 ? 0.0 : (waterConsumedMl / waterTargetMl).clamp(0.0, 1.0);
}

class HomeController extends ChangeNotifier {
  final LocalDatabase _database;
  final TaskLifecycleService _taskService;
  final WaterService _waterService;
  final ProgressionEngine _progressionEngine;
  final StreakCalculator _streakCalculator;
  final dynamic service;

  late HomeState state;

  HomeController({
    LocalDatabase? database,
    TaskLifecycleService? taskService,
    WaterService? waterService,
    ProgressionEngine? progressionEngine,
    StreakCalculator? streakCalculator,
    this.service,
  })  : _database = database ?? LocalDatabase.instance,
        _taskService = taskService ??
            TaskLifecycleService(
              taskRepository: TaskRepository(database ?? LocalDatabase.instance),
              database: database ?? LocalDatabase.instance,
            ),
        _waterService = waterService ??
            WaterService(HealthRepository(database ?? LocalDatabase.instance)),
        _progressionEngine = progressionEngine ?? ProgressionEngine(),
        _streakCalculator = streakCalculator ?? StreakCalculator() {
    _loadState();
    _database.changes.addListener(_onDataChanged);
  }

  void load() {
    _loadState();
    notifyListeners();
  }

  void _loadState() {
    final tasks = _taskService.getTodayTasks();
    final completed = tasks.where((t) => t.isCompleted).length;
    final total = tasks.length;
    final active = tasks.where((t) => !t.isCompleted).firstOrNull;

    final waterHistory = _waterService.getTodayEntries();
    final consumedWater = waterHistory.fold<int>(0, (sum, item) => sum + item.amountMl);

    final user = _database.getOrCreateProfile();
    final streak = _database.getStreak();
    final level = _progressionEngine.calculateLevel(user.xp);
    final title = _progressionEngine.getDisciplineTitle(level);

    state = HomeState(
      tasksCompleted: completed,
      tasksTotal: total,
      activeTask: active,
      waterConsumedMl: consumedWater,
      waterTargetMl: 2500,
      streakDays: streak.currentStreak,
      userLevel: level,
      disciplineTitle: title,
    );
  }

  void completeTask(String taskId) {
    _taskService.completeTaskWithAction(taskId);
  }

  void logWater(int amountMl) {
    _waterService.logWater(amountMl: amountMl);
  }

  void _onDataChanged() {
    _loadState();
    notifyListeners();
  }

  @override
  void dispose() {
    _database.changes.removeListener(_onDataChanged);
    super.dispose();
  }
}
