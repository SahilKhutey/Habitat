// Habitat Cross-Platform Notification Service & Deep-Link Resolution
import 'dart:convert';
import 'package:flutter/foundation.dart';

@immutable
class NotificationPayload {
  final String type; // 'alarm' or 'task'
  final String? alarmId;
  final String taskId;

  const NotificationPayload({
    required this.type,
    this.alarmId,
    required this.taskId,
  });

  String toJsonString() => jsonEncode({
        'type': type,
        if (alarmId != null) 'alarmId': alarmId,
        'taskId': taskId,
      });

  static NotificationPayload? fromJsonString(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return NotificationPayload(
        type: map['type'] as String? ?? 'task',
        alarmId: map['alarmId'] as String?,
        taskId: map['taskId'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  String get deepLinkRoute => '/tasks/$taskId/action';
}

abstract interface class HabitatNotificationService {
  Future<bool> requestPermission();

  Future<void> showTaskReminder({
    required String taskId,
    required String title,
    required String body,
  });

  Future<void> showAlarmNotification({
    required String alarmId,
    required String taskId,
    required String title,
    required String body,
  });

  Future<void> cancel(String notificationId);
}

class StandardNotificationService implements HabitatNotificationService {
  final List<NotificationPayload> deliveredPayloads = [];

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> showTaskReminder({
    required String taskId,
    required String title,
    required String body,
  }) async {
    final payload = NotificationPayload(type: 'task', taskId: taskId);
    deliveredPayloads.add(payload);
  }

  @override
  Future<void> showAlarmNotification({
    required String alarmId,
    required String taskId,
    required String title,
    required String body,
  }) async {
    final payload = NotificationPayload(type: 'alarm', alarmId: alarmId, taskId: taskId);
    deliveredPayloads.add(payload);
  }

  @override
  Future<void> cancel(String notificationId) async {
    deliveredPayloads.removeWhere((p) => p.alarmId == notificationId || p.taskId == notificationId);
  }
}
