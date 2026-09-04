// Habitat 7-Step Task Creation Wizard Controller
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/action_model.dart';
import '../domain/models/alarm_model.dart';
import '../domain/models/retry_rules_model.dart';
import '../domain/models/schedule_model.dart';
import '../domain/models/task_model.dart';
import '../domain/services/task_service.dart';

class CreateTaskController extends ChangeNotifier {
  final TaskService _taskService;

  int currentStep = 0;

  // Step 0: Identity
  String title = 'Morning Sunlight Walk';
  String description =
      'Step outside and absorb morning sunlight for circadian alignment.';
  TaskCategory category = TaskCategory.morning;
  TaskDifficulty difficulty = TaskDifficulty.medium;

  // Step 1: Schedule
  ScheduleRecurrenceType recurrence = ScheduleRecurrenceType.daily;
  String timeOfDay = '07:00';
  List<int> repeatDays = [1, 2, 3, 4, 5, 6, 7];

  // Step 2 & 3: Action & Verification
  ActionType actionType = ActionType.photo;
  String actionInstruction = 'Take a clear photo in outdoor morning sunlight.';
  VerificationType verificationType = VerificationType.photoProof;

  // Step 4: Alarm
  bool alarmEnabled = true;
  int sirenVolume = 70;
  DisciplineMode disciplineMode = DisciplineMode.discipline;

  // Step 5: Retry Rules
  bool retryEnabled = true;
  int retryIntervalMinutes = 5;
  int maxAttempts = 3;

  CreateTaskController({required TaskService taskService})
      : _taskService = taskService;

  int get calculatedXp {
    final base = switch (difficulty) {
      TaskDifficulty.easy => 20,
      TaskDifficulty.medium => 30,
      TaskDifficulty.hard => 50,
    };
    return base;
  }

  void nextStep() {
    if (currentStep < 6) {
      currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  void updateBasicInfo({
    String? newTitle,
    String? newDescription,
    TaskCategory? newCategory,
    TaskDifficulty? newDifficulty,
  }) {
    if (newTitle != null) title = newTitle;
    if (newDescription != null) description = newDescription;
    if (newCategory != null) category = newCategory;
    if (newDifficulty != null) difficulty = newDifficulty;
    notifyListeners();
  }

  void updateSchedule({
    ScheduleRecurrenceType? newRecurrence,
    String? newTime,
    List<int>? newDays,
  }) {
    if (newRecurrence != null) recurrence = newRecurrence;
    if (newTime != null) timeOfDay = newTime;
    if (newDays != null) repeatDays = newDays;
    notifyListeners();
  }

  void updateActionAndVerification({
    ActionType? newActionType,
    String? newInstruction,
    VerificationType? newVerificationType,
  }) {
    if (newActionType != null) {
      actionType = newActionType;
      verificationType = newActionType == ActionType.video
          ? VerificationType.videoProof
          : VerificationType.photoProof;
    }
    if (newInstruction != null) actionInstruction = newInstruction;
    if (newVerificationType != null) verificationType = newVerificationType;
    notifyListeners();
  }

  void updateAlarm({
    bool? enabled,
    int? volume,
    DisciplineMode? mode,
  }) {
    if (enabled != null) alarmEnabled = enabled;
    if (volume != null) sirenVolume = volume;
    if (mode != null) disciplineMode = mode;
    notifyListeners();
  }

  void updateRetryRules({
    bool? enabled,
    int? intervalMinutes,
    int? maxRetries,
  }) {
    if (enabled != null) retryEnabled = enabled;
    if (intervalMinutes != null) retryIntervalMinutes = intervalMinutes;
    if (maxRetries != null) maxAttempts = maxRetries;
    notifyListeners();
  }

  TaskModel saveTask() {
    final taskId = 'task-${const Uuid().v4()}';
    final now = DateTime.now();

    final task = TaskModel(
      id: taskId,
      title: title.trim().isEmpty ? 'Daily Discipline' : title.trim(),
      description: description.trim(),
      category: category,
      difficulty: difficulty,
      status: TaskStatus.ready,
      baseXp: calculatedXp,
      estimatedDurationSec: 60,
      active: true,
      createdAt: now,
      updatedAt: now,
      schedule: TaskScheduleModel(
        recurrenceType: recurrence,
        timeOfDay: timeOfDay,
        repeatDays: repeatDays,
      ),
      action: TaskActionModel(
        id: 'action-$taskId',
        type: actionType,
        title: title,
        instruction: actionInstruction,
        verificationType: verificationType,
      ),
      alarm: alarmEnabled
          ? TaskAlarmModel(
              id: 'alarm-$taskId',
              taskId: taskId,
              timeOfDay: timeOfDay,
              isEnabled: true,
              repeatDays: repeatDays,
              retryIntervalMinutes: retryIntervalMinutes,
              maxRetries: maxAttempts,
              sirenVolume: sirenVolume,
              disciplineMode: disciplineMode,
            )
          : null,
      retryRules: TaskRetryRulesModel(
        enabled: retryEnabled,
        retryIntervalMinutes: retryIntervalMinutes,
        maxAttempts: maxAttempts,
      ),
    );

    _taskService.saveTask(task);
    return task;
  }
}
