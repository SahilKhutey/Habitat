// Habitat Task Service & Repository Orchestrator
import '../../../../database/local_database.dart';
import '../models/action_model.dart';
import '../models/alarm_model.dart';
import '../models/retry_rules_model.dart';
import '../models/schedule_model.dart';
import '../models/task_model.dart';

class TaskService {
  final LocalDatabase _database;
  final Set<String> _pausedTaskIds = {};

  TaskService(this._database);

  List<TaskModel> getAllTasks() {
    final localTasks = _database.getAllTasks();
    final alarms = _database.getAllAlarms();
    final attempts = _database.getAllAttempts();

    return localTasks
        .map((lt) => _mapLocalToModel(lt, alarms, attempts))
        .toList();
  }

  TaskModel? getTaskById(String id) {
    final lt = _database.getTask(id);
    if (lt == null) return null;
    final alarms = _database.getAllAlarms();
    final attempts = _database.getAllAttempts();
    return _mapLocalToModel(lt, alarms, attempts);
  }

  List<TaskModel> getTasksByFilter(String filter) {
    final all = getAllTasks();
    final today = DateTime.now();

    return switch (filter.toUpperCase()) {
      'ACTIVE' => all
          .where((t) =>
              t.active &&
              t.status != TaskStatus.archived &&
              t.status != TaskStatus.paused)
          .toList(),
      'SCHEDULED' => all
          .where((t) => t.active && t.alarm != null && t.alarm!.isEnabled)
          .toList(),
      'COMPLETED' =>
        all.where((t) => t.status == TaskStatus.completed).toList(),
      'MISSED' => all
          .where((t) =>
              t.status == TaskStatus.missed || t.status == TaskStatus.failed)
          .toList(),
      'PAUSED' => all.where((t) => t.status == TaskStatus.paused).toList(),
      'ARCHIVED' => all.where((t) => t.status == TaskStatus.archived).toList(),
      _ => all.where((t) => t.status != TaskStatus.archived).toList(),
    };
  }

  void saveTask(TaskModel task) {
    _database.saveTask(LocalTask(
      id: task.id,
      title: task.title,
      description: task.description,
      category: task.categoryDisplayName,
      taskType: task.action.type == ActionType.video ? 'VIDEO' : 'PHOTO',
      requiresPhoto: task.action.type == ActionType.photo,
      requiresVideo: task.action.type == ActionType.video,
      requiresVerification: true,
      active: task.active && task.status != TaskStatus.archived,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
    ));

    if (task.alarm != null) {
      _database.saveAlarm(LocalAlarm(
        id: task.alarm!.id,
        taskId: task.id,
        scheduledTime: task.alarm!.timeOfDay,
        enabled: task.alarm!.isEnabled,
        repeatDays: task.alarm!.repeatDays,
        retryIntervalMinutes: task.alarm!.retryIntervalMinutes,
        maxRetries: task.alarm!.maxRetries,
        createdAt: DateTime.now(),
      ));
    }
  }

  void pauseTask(String taskId) {
    _pausedTaskIds.add(taskId);
    final task = getTaskById(taskId);
    if (task == null) return;
    saveTask(task.copyWith(status: TaskStatus.paused, active: false));
  }

  void resumeTask(String taskId) {
    _pausedTaskIds.remove(taskId);
    final task = getTaskById(taskId);
    if (task == null) return;
    saveTask(task.copyWith(status: TaskStatus.ready, active: true));
  }

  void archiveTask(String taskId) {
    _pausedTaskIds.remove(taskId);
    final task = getTaskById(taskId);
    if (task == null) return;
    saveTask(task.copyWith(status: TaskStatus.archived, active: false));
  }

  TaskModel _mapLocalToModel(
    LocalTask lt,
    List<LocalAlarm> alarms,
    List<LocalTaskAttempt> attempts,
  ) {
    LocalAlarm? associatedAlarm;
    for (final a in alarms) {
      if (a.taskId == lt.id) {
        associatedAlarm = a;
        break;
      }
    }

    final taskAttempts = attempts.where((a) => a.taskId == lt.id).toList();
    TaskStatus status = TaskStatus.ready;

    if (_pausedTaskIds.contains(lt.id)) {
      status = TaskStatus.paused;
    } else if (!lt.active) {
      status = TaskStatus.archived;
    } else if (taskAttempts.isNotEmpty) {
      final latest = taskAttempts.last;
      status = switch (latest.status) {
        'COMPLETED' => TaskStatus.completed,
        'FAILED' => TaskStatus.failed,
        'RETRY' => TaskStatus.failed,
        'AWAITING_ACTION' || 'RINGING' => TaskStatus.active,
        _ => TaskStatus.ready,
      };
    }

    final actionType = lt.taskType == 'VIDEO'
        ? ActionType.video
        : lt.taskType == 'AUDIO'
            ? ActionType.custom
            : ActionType.photo;

    final verificationType = actionType == ActionType.video
        ? VerificationType.videoProof
        : VerificationType.photoProof;

    final category = _parseCategory(lt.category);

    return TaskModel(
      id: lt.id,
      title: lt.title,
      description: lt.description,
      category: category,
      difficulty: TaskDifficulty.medium,
      status: status,
      baseXp: 30,
      estimatedDurationSec: 60,
      active: lt.active,
      createdAt: lt.createdAt,
      updatedAt: lt.updatedAt,
      schedule: TaskScheduleModel(
        timeOfDay: associatedAlarm?.scheduledTime ?? '07:00',
        repeatDays: associatedAlarm?.repeatDays ?? const [1, 2, 3, 4, 5, 6, 7],
      ),
      action: TaskActionModel(
        id: 'action-${lt.id}',
        type: actionType,
        title: lt.title,
        instruction:
            'Complete ${lt.title} and capture required proof evidence.',
        verificationType: verificationType,
      ),
      alarm: associatedAlarm != null
          ? TaskAlarmModel(
              id: associatedAlarm.id,
              taskId: lt.id,
              timeOfDay: associatedAlarm.scheduledTime,
              isEnabled: associatedAlarm.enabled,
              repeatDays: associatedAlarm.repeatDays,
              retryIntervalMinutes: associatedAlarm.retryIntervalMinutes,
              maxRetries: associatedAlarm.maxRetries,
            )
          : null,
      retryRules: const TaskRetryRulesModel(),
    );
  }

  TaskCategory _parseCategory(String cat) => switch (cat.toUpperCase()) {
        'MORNING' => TaskCategory.morning,
        'EXERCISE' || 'PHYSICAL' => TaskCategory.physical,
        'MIND' => TaskCategory.mind,
        'ENVIRONMENT' => TaskCategory.environment,
        'PERSONAL' => TaskCategory.personal,
        'ROUTINE' => TaskCategory.routine,
        _ => TaskCategory.custom,
      };
}
