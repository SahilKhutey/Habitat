// Habitat Alarm Service & Native Synchronization
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/alarm/native_alarm_service.dart';
import '../../../../database/local_database.dart';
import '../models/alarm_model.dart';

/// SharedPreferences key read by BootReceiver.kt on BOOT_COMPLETED to
/// re-arm alarms that were cleared from AlarmManager by the OS reboot.
const _kPendingAlarmsKey = 'habitat_pending_alarms';

class AlarmService {
  final LocalDatabase _database;

  AlarmService(this._database);

  List<TaskAlarmModel> getAllAlarms() {
    final localAlarms = _database.getAllAlarms();
    return localAlarms.map(_mapLocalToModel).toList();
  }

  List<TaskAlarmModel> getAlarmsByFilter(String filter) {
    final alarms = getAllAlarms();
    return switch (filter.toUpperCase()) {
      'ACTIVE' => alarms.where((a) => a.isEnabled).toList(),
      'UPCOMING' => alarms.where((a) => a.isEnabled).toList(),
      'DISABLED' => alarms.where((a) => !a.isEnabled).toList(),
      _ => alarms,
    };
  }

  Future<void> toggleAlarm(String alarmId, bool isEnabled) async {
    final alarms = _database.getAllAlarms();
    final index = alarms.indexWhere((a) => a.id == alarmId);
    if (index < 0) return;

    final existing = alarms[index];
    final updated = LocalAlarm(
      id: existing.id,
      taskId: existing.taskId,
      scheduledTime: existing.scheduledTime,
      enabled: isEnabled,
      repeatType: existing.repeatType,
      repeatDays: existing.repeatDays,
      retryIntervalMinutes: existing.retryIntervalMinutes,
      maxRetries: existing.maxRetries,
      createdAt: existing.createdAt,
    );

    _database.saveAlarm(updated);

    if (isEnabled) {
      final task = _database.getTask(existing.taskId);
      final now = DateTime.now();
      final parts = existing.scheduledTime.split(':');
      final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 7 : 7;
      final min = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      var trigger = DateTime(now.year, now.month, now.day, hour, min);
      if (trigger.isBefore(now)) {
        trigger = trigger.add(const Duration(days: 1));
      }

      await NativeAlarmService.scheduleExactAlarm(
        missionId: existing.id,
        taskTitle: task?.title ?? 'Discipline Commitment',
        triggerTime: trigger,
        sirenVolume: 70,
      );
      // Persist for BootReceiver.kt so alarm survives device reboot
      await _persistAlarm(
        missionId: existing.id,
        taskTitle: task?.title ?? 'Discipline Commitment',
        triggerEpochMs: trigger.millisecondsSinceEpoch,
      );
    } else {
      await NativeAlarmService.cancelAlarm(existing.id);
      await _removeFromPersisted(existing.id);
    }
  }

  TaskAlarmModel _mapLocalToModel(LocalAlarm la) {
    return TaskAlarmModel(
      id: la.id,
      taskId: la.taskId,
      timeOfDay: la.scheduledTime,
      isEnabled: la.enabled,
      repeatDays: la.repeatDays,
      retryIntervalMinutes: la.retryIntervalMinutes,
      maxRetries: la.maxRetries,
      sirenVolume: 70,
      disciplineMode: DisciplineMode.discipline,
    );
  }

  // ── Boot-restore persistence helpers ──────────────────────────────────────

  /// Upserts an alarm entry in SharedPreferences so [BootReceiver] can
  /// re-arm it after a device reboot via [restoreActiveAlarms()].
  Future<void> _persistAlarm({
    required String missionId,
    required String taskTitle,
    required int triggerEpochMs,
    int sirenVolume = 70,
    int attemptIndex = 1,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPendingAlarmsKey);
      final list = raw != null ? List<Map<String, dynamic>>.from(
        (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)),
      ) : <Map<String, dynamic>>[];

      // Remove existing entry for this missionId (idempotent upsert)
      list.removeWhere((e) => e['missionId'] == missionId);
      list.add({
        'missionId':     missionId,
        'taskTitle':     taskTitle,
        'triggerEpochMs': triggerEpochMs,
        'sirenVolume':   sirenVolume,
        'attemptIndex':  attemptIndex,
      });

      await prefs.setString(_kPendingAlarmsKey, jsonEncode(list));
    } catch (e) {
      debugPrint('[AlarmService] Failed to persist alarm for boot restore: $e');
    }
  }

  /// Removes an alarm from the boot-restore list when it is cancelled or completed.
  Future<void> _removeFromPersisted(String missionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPendingAlarmsKey);
      if (raw == null) return;
      final list = List<Map<String, dynamic>>.from(
        (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      list.removeWhere((e) => e['missionId'] == missionId);
      await prefs.setString(_kPendingAlarmsKey, jsonEncode(list));
    } catch (e) {
      debugPrint('[AlarmService] Failed to remove alarm from persisted list: $e');
    }
  }
}
