// Habitat Alarm Service & Native Synchronization
import '../../../../core/alarm/native_alarm_service.dart';
import '../../../../database/local_database.dart';
import '../models/alarm_model.dart';

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
    } else {
      await NativeAlarmService.cancelAlarm(existing.id);
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
}
