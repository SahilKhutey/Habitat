// Habitat Notification Settings Domain Model
import 'package:flutter/foundation.dart';

@immutable
class NotificationSettingsModel {
  final bool taskRemindersEnabled;
  final bool alarmNotificationsEnabled;
  final bool progressUpdatesEnabled;
  final bool achievementAlertsEnabled;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;

  const NotificationSettingsModel({
    this.taskRemindersEnabled = true,
    this.alarmNotificationsEnabled = true,
    this.progressUpdatesEnabled = true,
    this.achievementAlertsEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
  });

  NotificationSettingsModel copyWith({
    bool? taskRemindersEnabled,
    bool? alarmNotificationsEnabled,
    bool? progressUpdatesEnabled,
    bool? achievementAlertsEnabled,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) =>
      NotificationSettingsModel(
        taskRemindersEnabled: taskRemindersEnabled ?? this.taskRemindersEnabled,
        alarmNotificationsEnabled:
            alarmNotificationsEnabled ?? this.alarmNotificationsEnabled,
        progressUpdatesEnabled:
            progressUpdatesEnabled ?? this.progressUpdatesEnabled,
        achievementAlertsEnabled:
            achievementAlertsEnabled ?? this.achievementAlertsEnabled,
        quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
        quietHoursStart: quietHoursStart ?? this.quietHoursStart,
        quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      );

  Map<String, dynamic> toMap() => {
        'taskReminders': taskRemindersEnabled,
        'alarmNotifications': alarmNotificationsEnabled,
        'progressUpdates': progressUpdatesEnabled,
        'achievementAlerts': achievementAlertsEnabled,
        'quietHours': quietHoursEnabled,
        'quietHoursStart': quietHoursStart,
        'quietHoursEnd': quietHoursEnd,
      };

  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) =>
      NotificationSettingsModel(
        taskRemindersEnabled: map['taskReminders'] ?? true,
        alarmNotificationsEnabled: map['alarmNotifications'] ?? true,
        progressUpdatesEnabled: map['progressUpdates'] ?? true,
        achievementAlertsEnabled: map['achievementAlerts'] ?? true,
        quietHoursEnabled: map['quietHours'] ?? false,
        quietHoursStart: map['quietHoursStart'] ?? '22:00',
        quietHoursEnd: map['quietHoursEnd'] ?? '07:00',
      );
}
