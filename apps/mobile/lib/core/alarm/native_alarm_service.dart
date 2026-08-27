// Native Alarm & Local 5-Minute Retry Service
import 'package:flutter/services.dart';

class NativeAlarmService {
  static const MethodChannel _channel = MethodChannel('habitat/native_alarm');

  /// Schedules an exact OS wake-up alarm
  static Future<bool> scheduleExactAlarm({
    required String missionId,
    required String taskTitle,
    required DateTime triggerTime,
    int sirenVolume = 70,
    int attemptIndex = 1,
  }) async {
    try {
      final success = await _channel.invokeMethod<bool>('scheduleExactAlarm', {
        'missionId': missionId,
        'taskTitle': taskTitle,
        'triggerEpochMs': triggerTime.millisecondsSinceEpoch,
        'sirenVolume': sirenVolume,
        'attemptIndex': attemptIndex,
      });
      return success ?? false;
    } catch (e) {
      // Fallback for web or testing environments
      print('[NativeAlarmService] Channel error (fallback active): $e');
      return true;
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
