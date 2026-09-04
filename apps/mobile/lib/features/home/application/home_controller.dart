import 'package:flutter/foundation.dart';
import '../../../../database/local_database.dart';
import '../../alarms/domain/services/alarm_scheduler.dart';
import '../../gamification/domain/services/progression_engine.dart';
import '../../health/domain/repositories/health_repository.dart';
import '../../health/domain/services/water_service.dart';
import '../../tasks/domain/repositories/task_repository.dart';
import '../../tasks/domain/services/task_lifecycle_service.dart';
import '../domain/models/home_state_model.dart';
import '../domain/services/home_service.dart';

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

  double get waterProgress => waterTargetMl <= 0
      ? 0.0
      : (waterConsumedMl / waterTargetMl).clamp(0.0, 1.0);
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
              taskRepository:
                  TaskRepository(database ?? LocalDatabase.instance),
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
    final consumedWater =
        waterHistory.fold<int>(0, (sum, item) => sum + item.milliliters);

    final user = _database.getOrCreateProfile();
    final streak = _database.getStreak();
    final level = _progressionEngine.calculateLevel(_database.getTotalXP());
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

  HomeLoadStatus get status => HomeLoadStatus.ready;
  HomeStateModel? get model => HomeService(_database).load();
  String? get errorMessage => null;
  void refresh() => load();

  void completeTask(String taskId) {
    _taskService.completeTaskWithAction(taskId);
  }

  void logWater(int amountMl) {
    _waterService.logWater(amountMl: amountMl);
  }

  void logMeal() {
    _database.addMeal(type: 'snack', notes: 'Healthy Fuel');
    load();
  }

  void toggleNap() {
    final active = _database.getAllNapEntries().any((n) => n.isRunning);
    if (active) {
      _database.stopNap();
    } else {
      _database.startNap();
    }
    load();
  }

  void createFirstTask() {}

  String startAction(String taskId) {
    final attemptId = 'att_${DateTime.now().millisecondsSinceEpoch}';
    _database.saveAttempt(LocalTaskAttempt(
      id: attemptId,
      taskId: taskId,
      alarmId: 'adhoc',
      attemptNumber: 1,
      status: 'IN_PROGRESS',
      triggeredAt: DateTime.now(),
    ));
    return attemptId;
  }

  void completeAction(String attemptId, String taskId) {
    _database.completeTask(taskId);
    _database.updateAttemptStatus(
        attemptId: attemptId, status: 'COMPLETED', completedAt: DateTime.now());
    _database.awardXP(taskId: taskId, attemptId: attemptId, amount: 25);
    _database.updateStreak();
    load();
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
