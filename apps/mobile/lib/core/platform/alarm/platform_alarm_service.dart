// Habitat Cross-Platform Alarm Capability Layer
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../features/alarms/domain/services/alarm_scheduler.dart';

abstract interface class PlatformAlarmService {
  Future<bool> requestPermission();
  Future<void> schedule(HabitatAlarm alarm);
  Future<void> cancel(String alarmId);
  Future<void> cancelAll();
  Future<List<HabitatAlarm>> getScheduledAlarms();

  factory PlatformAlarmService.create() {
    if (kIsWeb) {
      return WebAlarmService();
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidAlarmService();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return IOSAlarmService();
    }
    return WebAlarmService();
  }
}

class AndroidAlarmService implements PlatformAlarmService {
  final Map<String, HabitatAlarm> _scheduledAlarms = {};

  @override
  Future<bool> requestPermission() async {
    // Android 12+ SCHEDULE_EXACT_ALARM or USE_EXACT_ALARM
    return true;
  }

  @override
  Future<void> schedule(HabitatAlarm alarm) async {
    _scheduledAlarms[alarm.id] = alarm;
    // In production, invokes MethodChannel to AlarmManager.setExactAndAllowWhileIdle()
  }

  @override
  Future<void> cancel(String alarmId) async {
    _scheduledAlarms.remove(alarmId);
    // In production, cancels PendingIntent via AlarmManager
  }

  @override
  Future<void> cancelAll() async {
    _scheduledAlarms.clear();
  }

  @override
  Future<List<HabitatAlarm>> getScheduledAlarms() async {
    return _scheduledAlarms.values.toList();
  }
}

class IOSAlarmService implements PlatformAlarmService {
  final Map<String, HabitatAlarm> _scheduledAlarms = {};

  @override
  Future<bool> requestPermission() async {
    // UNUserNotificationCenter requestAuthorization
    return true;
  }

  @override
  Future<void> schedule(HabitatAlarm alarm) async {
    _scheduledAlarms[alarm.id] = alarm;
    // In production, creates UNCalendarNotificationTrigger
  }

  @override
  Future<void> cancel(String alarmId) async {
    _scheduledAlarms.remove(alarmId);
  }

  @override
  Future<void> cancelAll() async {
    _scheduledAlarms.clear();
  }

  @override
  Future<List<HabitatAlarm>> getScheduledAlarms() async {
    return _scheduledAlarms.values.toList();
  }
}

class WebAlarmService implements PlatformAlarmService {
  final Map<String, HabitatAlarm> _scheduledAlarms = {};

  @override
  Future<bool> requestPermission() async {
    // Web notifications or in-app cues
    return true;
  }

  @override
  Future<void> schedule(HabitatAlarm alarm) async {
    _scheduledAlarms[alarm.id] = alarm;
  }

  @override
  Future<void> cancel(String alarmId) async {
    _scheduledAlarms.remove(alarmId);
  }

  @override
  Future<void> cancelAll() async {
    _scheduledAlarms.clear();
  }

  @override
  Future<List<HabitatAlarm>> getScheduledAlarms() async {
    return _scheduledAlarms.values.toList();
  }
}
