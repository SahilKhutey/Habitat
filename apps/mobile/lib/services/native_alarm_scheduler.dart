// Flutter Mobile Native Alarm Scheduler & Escalation Retry Engine
import 'dart:async';

class ScheduledAlarmOccurrence {
  final String occurrenceId;
  final String alarmId;
  final String missionId;
  final DateTime scheduledAt;
  final DateTime registeredAt;
  bool isCancelled;

  bool get isDisarmed => isCancelled;
  set isDisarmed(bool val) => isCancelled = val;

  ScheduledAlarmOccurrence({
    required this.occurrenceId,
    required this.alarmId,
    required this.missionId,
    required this.scheduledAt,
    required this.registeredAt,
    this.isCancelled = false,
  });
}

class NativeAlarmScheduler {
  static final NativeAlarmScheduler instance = NativeAlarmScheduler._internal();
  NativeAlarmScheduler._internal();

  final Map<String, ScheduledAlarmOccurrence> _osRegistry = {};
  final Map<String, Timer> _retryTimers = {};

  int get activeCount => _osRegistry.values.where((o) => !o.isCancelled).length;

  void reset() {
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();
    _osRegistry.clear();
  }

  /// Schedules an exact alarm idempotently
  ScheduledAlarmOccurrence scheduleExactAlarm({
    required String alarmId,
    required String missionId,
    required DateTime scheduledAt,
  }) {
    final occurrenceId = 'occ_${alarmId}_${scheduledAt.millisecondsSinceEpoch}';

    // 1. Check if already registered
    if (_osRegistry.containsKey(occurrenceId) &&
        !_osRegistry[occurrenceId]!.isCancelled) {
      return _osRegistry[occurrenceId]!;
    }

    final occurrence = ScheduledAlarmOccurrence(
      occurrenceId: occurrenceId,
      alarmId: alarmId,
      missionId: missionId,
      scheduledAt: scheduledAt,
      registeredAt: DateTime.now(),
    );

    _osRegistry[occurrenceId] = occurrence;
    return occurrence;
  }

  /// Triggered by Android AlarmManager or iOS UNNotification
  void onAlarmTriggered(
      {required String occurrenceId, int retryIntervalMinutes = 5}) {
    _retryTimers[occurrenceId]?.cancel();

    _retryTimers[occurrenceId] =
        Timer(Duration(minutes: retryIntervalMinutes), () {
      // Escalation retry fired if not completed
      final occurrence = _osRegistry[occurrenceId];
      if (occurrence != null && !occurrence.isCancelled) {
        onAlarmTriggered(
            occurrenceId: occurrenceId,
            retryIntervalMinutes: retryIntervalMinutes);
      }
    });
  }

  /// Disarms alarm upon mission completion and cancels any pending retry timers
  void onMissionCompleted({required String occurrenceId}) {
    _retryTimers[occurrenceId]?.cancel();
    _retryTimers.remove(occurrenceId);

    final occurrence = _osRegistry[occurrenceId];
    if (occurrence != null) {
      occurrence.isCancelled = true;
    }
  }

  /// Restores scheduled alarms following device reboot (BOOT_COMPLETED)
  int restorePendingAlarmsOnBoot(List<Map<String, dynamic>> pendingAlarms) {
    int count = 0;
    final now = DateTime.now();

    for (final item in pendingAlarms) {
      final scheduledAt = DateTime.parse(item['scheduledAt'] as String);
      if (scheduledAt.isAfter(now.subtract(const Duration(minutes: 10)))) {
        scheduleExactAlarm(
          alarmId: item['alarmId'] as String,
          missionId: item['missionId'] as String,
          scheduledAt: scheduledAt,
        );
        count++;
      }
    }
    return count;
  }

  int get registeredCount =>
      _osRegistry.values.where((o) => !o.isCancelled).length;
}
