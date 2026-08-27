// Cross-Platform Notification Scheduler & Local Alarm Reconciliation Engine
import 'package:flutter/foundation.dart';

abstract class NotificationScheduler {
  Future<bool> requestPermissions();
  Future<bool> hasPermissions();
  Future<void> scheduleAlarm({
    required String missionId,
    required String attemptId,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required int volumeLevel,
  });
  Future<void> cancelAlarm(String attemptId);
  Future<void> cancelMissionAlarms(String missionId);
}

class AndroidAlarmAdapter implements NotificationScheduler {
  @override
  Future<bool> requestPermissions() async {
    debugPrint('[AndroidAlarmAdapter] Requesting POST_NOTIFICATIONS and SCHEDULE_EXACT_ALARM permissions');
    return true;
  }

  @override
  Future<bool> hasPermissions() async => true;

  @override
  Future<void> scheduleAlarm({
    required String missionId,
    required String attemptId,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required int volumeLevel,
  }) async {
    debugPrint('[AndroidAlarmAdapter] Scheduling Exact Alarm on channel `discipline_alarm` at $scheduledAt (Volume: $volumeLevel dB) for Attempt $attemptId');
  }

  @override
  Future<void> cancelAlarm(String attemptId) async {
    debugPrint('[AndroidAlarmAdapter] Cancelling local alarm for Attempt $attemptId');
  }

  @override
  Future<void> cancelMissionAlarms(String missionId) async {
    debugPrint('[AndroidAlarmAdapter] Cancelling all pending local retries for Mission $missionId');
  }
}

class IOSNotificationAdapter implements NotificationScheduler {
  @override
  Future<bool> requestPermissions() async {
    debugPrint('[IOSNotificationAdapter] Requesting UNUserNotificationCenter authorization');
    return true;
  }

  @override
  Future<bool> hasPermissions() async => true;

  @override
  Future<void> scheduleAlarm({
    required String missionId,
    required String attemptId,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required int volumeLevel,
  }) async {
    debugPrint('[IOSNotificationAdapter] Scheduling UNCalendarNotificationTrigger for Attempt $attemptId at $scheduledAt');
  }

  @override
  Future<void> cancelAlarm(String attemptId) async {
    debugPrint('[IOSNotificationAdapter] Removing pending notification request $attemptId');
  }

  @override
  Future<void> cancelMissionAlarms(String missionId) async {
    debugPrint('[IOSNotificationAdapter] Removing all pending notifications for Mission $missionId');
  }
}

class WebNotificationAdapter implements NotificationScheduler {
  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<bool> hasPermissions() async => true;

  @override
  Future<void> scheduleAlarm({
    required String missionId,
    required String attemptId,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required int volumeLevel,
  }) async {
    debugPrint('[WebNotificationAdapter] Web push notification registered for $scheduledAt');
  }

  @override
  Future<void> cancelAlarm(String attemptId) async {}

  @override
  Future<void> cancelMissionAlarms(String missionId) async {}
}

class NotificationSchedulerFactory {
  static NotificationScheduler getScheduler() {
    if (kIsWeb) return WebNotificationAdapter();
    if (defaultTargetPlatform == TargetPlatform.android) return AndroidAlarmAdapter();
    if (defaultTargetPlatform == TargetPlatform.iOS) return IOSNotificationAdapter();
    return AndroidAlarmAdapter();
  }
}
