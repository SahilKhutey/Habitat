// Habitat Native Alarm Scheduler & Retry Policy Engine
import 'package:flutter/foundation.dart';
import '../../../../database/local_database.dart';

@immutable
class HabitatAlarm {
  final String id;
  final String taskId;
  final String title;
  final TimeOfDay time;
  final List<int> recurringDays;
  final bool isEnabled;
  final int retryCount;
  final int retryIntervalMinutes;

  const HabitatAlarm({
    required this.id,
    required this.taskId,
    required this.title,
    required this.time,
    this.recurringDays = const [1, 2, 3, 4, 5, 6, 7],
    this.isEnabled = true,
    this.retryCount = 0,
    this.retryIntervalMinutes = 5,
  });

  TimeOfDay get scheduledTime => time;
  String get taskTitle => title;
  List<int> get repeatDays => recurringDays;

  HabitatAlarm copyWith({
    String? id,
    String? taskId,
    String? title,
    TimeOfDay? time,
    List<int>? recurringDays,
    bool? isEnabled,
    int? retryCount,
    int? retryIntervalMinutes,
  }) {
    return HabitatAlarm(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      time: time ?? this.time,
      recurringDays: recurringDays ?? this.recurringDays,
      isEnabled: isEnabled ?? this.isEnabled,
      retryCount: retryCount ?? this.retryCount,
      retryIntervalMinutes: retryIntervalMinutes ?? this.retryIntervalMinutes,
    );
  }
}

abstract interface class IAlarmScheduler {
  Future<void> schedule(HabitatAlarm alarm);
  Future<void> cancel(String alarmId);
  Future<void> reschedule(HabitatAlarm alarm);
  Future<HabitatAlarm?> handleAlarmFired(String alarmId);
  Future<HabitatAlarm> applyRetryPolicy(HabitatAlarm alarm);
}

class AlarmScheduler implements IAlarmScheduler {
  final Map<String, HabitatAlarm> _activeAlarms = {};

  @override
  Future<void> schedule(HabitatAlarm alarm) async {
    _activeAlarms[alarm.id] = alarm;
  }

  @override
  Future<void> cancel(String alarmId) async {
    _activeAlarms.remove(alarmId);
  }

  @override
  Future<void> reschedule(HabitatAlarm alarm) async {
    _activeAlarms[alarm.id] = alarm;
  }

  @override
  Future<HabitatAlarm?> handleAlarmFired(String alarmId) async {
    return _activeAlarms[alarmId];
  }

  @override
  Future<HabitatAlarm> applyRetryPolicy(HabitatAlarm alarm) async {
    final nextMinute = (alarm.time.minute + alarm.retryIntervalMinutes) % 60;
    final nextHour = (alarm.time.hour + ((alarm.time.minute + alarm.retryIntervalMinutes) ~/ 60)) % 24;
    
    final updated = alarm.copyWith(
      time: TimeOfDay(hour: nextHour, minute: nextMinute),
      retryCount: alarm.retryCount + 1,
    );
    _activeAlarms[alarm.id] = updated;
    return updated;
  }

  List<HabitatAlarm> getScheduledAlarms() => _activeAlarms.values.toList();
}
