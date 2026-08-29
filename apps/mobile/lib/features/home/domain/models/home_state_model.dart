// Habitat Home Domain Models & State Contracts
import 'package:flutter/foundation.dart';

enum HomeLoadStatus {
  initial,
  loading,
  ready,
  refreshing,
  empty,
  offline,
  error,
}

enum CurrentActionStatus {
  noAction,
  upcoming,
  ready,
  active,
  completed,
  missed,
  retryRequired,
}

@immutable
class HomeUserSummary {
  final String displayName;
  final DateTime date;
  final String? contextMotto;

  const HomeUserSummary({
    required this.displayName,
    required this.date,
    this.contextMotto,
  });

  String get greeting {
    final hour = date.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

@immutable
class CurrentAction {
  final String taskId;
  final String title;
  final String detail;
  final CurrentActionStatus status;
  final DateTime? scheduledFor;
  final String category;
  final String taskType;

  const CurrentAction({
    required this.taskId,
    required this.title,
    required this.detail,
    required this.status,
    this.scheduledFor,
    this.category = 'DISCIPLINE',
    this.taskType = 'PHOTO',
  });

  bool get isActionable =>
      status == CurrentActionStatus.ready ||
      status == CurrentActionStatus.active ||
      status == CurrentActionStatus.retryRequired;

  String get ctaLabel => switch (status) {
        CurrentActionStatus.active => 'Continue Action',
        CurrentActionStatus.retryRequired => 'Retry Verification',
        CurrentActionStatus.completed => 'Completed',
        CurrentActionStatus.missed => 'Action Missed',
        CurrentActionStatus.upcoming => 'View Details',
        CurrentActionStatus.ready => 'Start Action',
        CurrentActionStatus.noAction => 'Create First Task',
      };
}

@immutable
class HomeTaskPreview {
  final String id;
  final String title;
  final String detail;
  final String category;
  final String taskType;
  final DateTime? scheduledFor;

  const HomeTaskPreview({
    required this.id,
    required this.title,
    required this.detail,
    this.category = 'GENERAL',
    this.taskType = 'PHOTO',
    this.scheduledFor,
  });
}

@immutable
class DailyProgressSummary {
  final int totalTasks;
  final int completedTasks;
  final int missedTasks;

  const DailyProgressSummary({
    required this.totalTasks,
    required this.completedTasks,
    required this.missedTasks,
  });

  int get remainingTasks =>
      (totalTasks - completedTasks - missedTasks).clamp(0, totalTasks);

  double get completionPercentage =>
      totalTasks == 0 ? 0.0 : (completedTasks / totalTasks).clamp(0.0, 1.0);

  int get completionPercentInt => (completionPercentage * 100).round();
}

@immutable
class HealthSummary {
  final int waterMilliliters;
  final int waterTargetMilliliters;
  final int mealsLogged;
  final int mealTarget;
  final int napMinutes;
  final bool napRunning;

  const HealthSummary({
    required this.waterMilliliters,
    required this.waterTargetMilliliters,
    required this.mealsLogged,
    required this.mealTarget,
    required this.napMinutes,
    required this.napRunning,
  });

  double get waterPercentage => waterTargetMilliliters == 0
      ? 0.0
      : (waterMilliliters / waterTargetMilliliters).clamp(0.0, 1.0);

  double get mealsPercentage =>
      mealTarget == 0 ? 0.0 : (mealsLogged / mealTarget).clamp(0.0, 1.0);
}

@immutable
class StreakSummary {
  final int currentStreak;
  final int bestStreak;
  final String stageMotto;

  const StreakSummary({
    required this.currentStreak,
    required this.bestStreak,
    this.stageMotto = 'Sprout Stage',
  });
}

@immutable
class NotificationSummary {
  final int enabledAlarmCount;
  final bool hasUnreadAlerts;

  const NotificationSummary({
    required this.enabledAlarmCount,
    this.hasUnreadAlerts = false,
  });
}

@immutable
class HomeStateModel {
  final HomeUserSummary user;
  final CurrentAction? currentAction;
  final List<HomeTaskPreview> upcomingTasks;
  final DailyProgressSummary dailyProgress;
  final HealthSummary health;
  final StreakSummary streak;
  final NotificationSummary notifications;

  const HomeStateModel({
    required this.user,
    required this.currentAction,
    required this.upcomingTasks,
    required this.dailyProgress,
    required this.health,
    required this.streak,
    required this.notifications,
  });
}
