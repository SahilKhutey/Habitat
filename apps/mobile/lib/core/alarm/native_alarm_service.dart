// Native Alarm & Local 5-Minute Retry Service
import 'package:flutter/services.dart';

class ScheduleAlarmResult {
  final bool isScheduled;
  final bool isExact;
  final String? failureReason;

  const ScheduleAlarmResult({
    required this.isScheduled,
    required this.isExact,
    this.failureReason,
  });
}

class NativeAlarmService {
  static const MethodChannel _channel = MethodChannel('habitat/native_alarm');

  /// Schedules an exact OS wake-up alarm with native result status
  static Future<ScheduleAlarmResult> scheduleExactAlarm({
    required String missionId,
    required String taskTitle,
    required DateTime triggerTime,
    int sirenVolume = 70,
    int attemptIndex = 1,
  }) async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('scheduleExactAlarm', {
        'missionId': missionId,
        'taskTitle': taskTitle,
        'triggerEpochMs': triggerTime.millisecondsSinceEpoch,
        'sirenVolume': sirenVolume,
        'attemptIndex': attemptIndex,
      });
      final scheduled = res?['scheduled'] as bool? ?? true;
      final exact = res?['exact'] as bool? ?? false;
      final reason = res?['reason'] as String?;
      return ScheduleAlarmResult(
        isScheduled: scheduled,
        isExact: exact,
        failureReason: reason,
      );
    } catch (e) {
      // Fallback for web or testing environments
      return ScheduleAlarmResult(
        isScheduled: true,
        isExact: false,
        failureReason: 'FALLBACK_ACTIVE: $e',
      );
    }
  }

  /// Cancels scheduled alarm
  static Future<bool> cancelAlarm(String missionId) async {
    try {
      final success = await _channel.invokeMethod<bool>('cancelAlarm', {
        'missionId': missionId,
      });
      return success ?? false;
    } catch (e) {
      return true;
    }
  }

  /// Stops current siren audio playback
  static Future<bool> stopSiren() async {
    try {
      final success = await _channel.invokeMethod<bool>('stopSiren');
      return success ?? false;
    } catch (e) {
      return true;
    }
  }

  /// Schedules next 5-minute escalation retry
  static Future<void> arm5MinuteRetry({
    required String missionId,
    required String taskTitle,
    required int currentAttemptIndex,
    int retryMinutes = 5,
  }) async {
    final nextAttempt = currentAttemptIndex + 1;
    final nextTrigger = DateTime.now().add(Duration(minutes: retryMinutes));
    final nextVolume = nextAttempt == 2 ? 85 : 100;

    print('[NativeAlarmService] Arming 5-Min Retry for Attempt $nextAttempt at $nextTrigger (Volume: $nextVolume%)');

    await scheduleExactAlarm(
      missionId: missionId,
      taskTitle: taskTitle,
      triggerTime: nextTrigger,
      sirenVolume: nextVolume,
      attemptIndex: nextAttempt,
    );
  }
}
