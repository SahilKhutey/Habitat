// Offline Alarm & 5-Minute Escalation Service
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../database/local_database.dart';

class OfflineAlarmService {
  static final OfflineAlarmService instance = OfflineAlarmService._internal();
  OfflineAlarmService._internal();

  final Map<String, Timer> _activeRetryTimers = {};
  bool isTestMode = false; // When true: 30s trigger, 1 min retry

  int get retryIntervalMinutes => isTestMode ? 1 : 5;

  /// Trigger an alarm for a task and create an attempt
  LocalTaskAttempt triggerAlarm({required String taskId, required String alarmId}) {
    // 1. Check existing attempts count
    final existingAttempts = LocalDatabase.instance.getAttemptsForTask(taskId);
    final attemptNumber = existingAttempts.length + 1;

    final attempt = LocalTaskAttempt(
      id: const Uuid().v4(),
      taskId: taskId,
      alarmId: alarmId,
      attemptNumber: attemptNumber,
      status: 'RINGING',
      triggeredAt: DateTime.now(),
    );

    LocalDatabase.instance.recordAttempt(attempt);

    // 2. Schedule 5-minute escalation retry if not completed
    _scheduleRetry(taskId: taskId, alarmId: alarmId, attemptNumber: attemptNumber);

    return attempt;
  }

  void _scheduleRetry({required String taskId, required String alarmId, required int attemptNumber}) {
    _activeRetryTimers[taskId]?.cancel();

    _activeRetryTimers[taskId] = Timer(Duration(minutes: retryIntervalMinutes), () {
      // Re-trigger alarm if task is still not completed
      final task = LocalDatabase.instance.getTask(taskId);
      if (task != null && task.active) {
        triggerAlarm(taskId: taskId, alarmId: alarmId);
      }
    });
  }

  /// Mark task completed and immediately cancel any pending retry timers
  void cancelRetryAndComplete({required String taskId, required String attemptId}) {
    _activeRetryTimers[taskId]?.cancel();
    _activeRetryTimers.remove(taskId);

    // Award XP and advance streak
    LocalDatabase.instance.awardXP(taskId: taskId, amount: 20);
    LocalDatabase.instance.updateStreak();
  }
}
