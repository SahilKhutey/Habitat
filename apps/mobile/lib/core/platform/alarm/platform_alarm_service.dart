// Habitat Cross-Platform Native Alarm & Mission Execution Bridge (Phase 15)
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../features/alarms/domain/services/alarm_scheduler.dart';

@immutable
class NativeAlarmEvent {
  final String missionId;
  final String taskId;
  final String alarmId;
  final String taskTitle;
  final int attemptIndex;
  final String route;

  const NativeAlarmEvent({
    required this.missionId,
    required this.taskId,
    required this.alarmId,
    required this.taskTitle,
    this.attemptIndex = 1,
    required this.route,
  });

  factory NativeAlarmEvent.fromMap(Map<dynamic, dynamic> map) {
    final missionId =
        map['missionId'] as String? ?? map['mission_id'] as String? ?? '';
    return NativeAlarmEvent(
      missionId: missionId,
      taskId: map['taskId'] as String? ?? map['task_id'] as String? ?? '',
      alarmId: map['alarmId'] as String? ?? map['alarm_id'] as String? ?? '',
      taskTitle: map['taskTitle'] as String? ??
          map['task_title'] as String? ??
          'Morning Mission',
      attemptIndex: (map['attemptIndex'] as num?)?.toInt() ??
          (map['attempt_index'] as num?)?.toInt() ??
          1,
      route: map['route'] as String? ?? '/mission/$missionId/active',
    );
  }
}

abstract interface class PlatformAlarmService {
  static PlatformAlarmService? _instance;
  static PlatformAlarmService get instance =>
      _instance ??= PlatformAlarmService.create();
  static set instance(PlatformAlarmService value) => _instance = value;

  Stream<NativeAlarmEvent> get alarmEvents;
  Future<bool> requestPermission();
  Future<void> schedule(HabitatAlarm alarm);
  Future<void> cancel(String alarmId);
  Future<void> cancelAll();
  Future<void> stopSiren();
  Future<List<HabitatAlarm>> getScheduledAlarms();
  void handleColdStartEvent(NativeAlarmEvent event);

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
  static const MethodChannel _channel =
      MethodChannel('com.habitat.app/native_alarm');
  final StreamController<NativeAlarmEvent> _eventController =
      StreamController<NativeAlarmEvent>.broadcast();
  final Map<String, HabitatAlarm> _scheduledAlarms = {};
  NativeAlarmEvent? _pendingColdStartEvent;

  AndroidAlarmService() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onAlarmTriggered' && call.arguments is Map) {
      final event = NativeAlarmEvent.fromMap(call.arguments as Map);
      _eventController.add(event);
    }
  }

  @override
  Stream<NativeAlarmEvent> get alarmEvents => _eventController.stream;

  @override
  void handleColdStartEvent(NativeAlarmEvent event) {
    _pendingColdStartEvent = event;
    _eventController.add(event);
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final canExact =
          await _channel.invokeMethod<bool>('canScheduleExactAlarms') ?? true;
      return canExact;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> schedule(HabitatAlarm alarm) async {
    _scheduledAlarms[alarm.id] = alarm;
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day,
        alarm.scheduledTime.hour, alarm.scheduledTime.minute);
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }

    try {
      await _channel.invokeMethod('scheduleExactAlarm', {
        'missionId': 'mission_${alarm.id}_${target.millisecondsSinceEpoch}',
        'taskId': alarm.taskId,
        'alarmId': alarm.id,
        'taskTitle': alarm.taskTitle,
        'triggerEpochMs': target.millisecondsSinceEpoch,
        'sirenVolume': 70,
        'attemptIndex': 1,
        'maxRetries': 6,
        'repeatDays': alarm.repeatDays,
      });
    } catch (_) {
      // Graceful local fallback
    }
  }

  @override
  Future<void> cancel(String alarmId) async {
    _scheduledAlarms.remove(alarmId);
    try {
      await _channel.invokeMethod('cancelAlarm', {'missionId': alarmId});
      await stopSiren();
    } catch (_) {}
  }

  @override
  Future<void> stopSiren() async {
    try {
      await _channel.invokeMethod('stopSiren');
    } catch (_) {}
  }

  @override
  Future<void> cancelAll() async {
    _scheduledAlarms.clear();
    await stopSiren();
  }

  @override
  Future<List<HabitatAlarm>> getScheduledAlarms() async {
    return _scheduledAlarms.values.toList();
  }
}

class IOSAlarmService implements PlatformAlarmService {
  static const MethodChannel _channel = MethodChannel('habitat/native_alarm');
  final StreamController<NativeAlarmEvent> _eventController =
      StreamController<NativeAlarmEvent>.broadcast();
  final Map<String, HabitatAlarm> _scheduledAlarms = {};

  @override
  Stream<NativeAlarmEvent> get alarmEvents => _eventController.stream;

  @override
  void handleColdStartEvent(NativeAlarmEvent event) {
    _eventController.add(event);
  }

  @override
  Future<bool> requestPermission() async {
    return true; // iOS permission requested in AppDelegate at launch
  }

  @override
  Future<void> schedule(HabitatAlarm alarm) async {
    _scheduledAlarms[alarm.id] = alarm;

    final now = DateTime.now();
    var target = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.scheduledTime.hour,
      alarm.scheduledTime.minute,
    );
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }

    try {
      // Triggers AppDelegate.scheduleAlarmChain() — 6 notifications at
      // T+0, T+5, T+10, T+15, T+20, T+25 min with Time Sensitive level.
      await _channel.invokeMethod<bool>('scheduleExactAlarm', {
        'missionId': alarm.id,
        'taskTitle': alarm.taskTitle,
        'triggerEpochMs': target.millisecondsSinceEpoch,
        'sirenVolume': 70,
        'attemptIndex': 1,
      });
    } catch (e) {
      // Graceful degradation — log but do not crash
      debugPrint('[IOSAlarmService] scheduleExactAlarm channel error: $e');
    }
  }

  @override
  Future<void> cancel(String alarmId) async {
    _scheduledAlarms.remove(alarmId);
    try {
      await _channel.invokeMethod<bool>('cancelAlarm', {'missionId': alarmId});
    } catch (e) {
      debugPrint('[IOSAlarmService] cancelAlarm channel error: $e');
    }
  }

  @override
  Future<void> stopSiren() async {
    try {
      await _channel.invokeMethod<bool>('stopSiren');
    } catch (e) {
      debugPrint('[IOSAlarmService] stopSiren channel error: $e');
    }
  }

  @override
  Future<void> cancelAll() async {
    final ids = _scheduledAlarms.keys.toList();
    _scheduledAlarms.clear();
    for (final id in ids) {
      try {
        await _channel.invokeMethod<bool>('cancelAlarm', {'missionId': id});
      } catch (_) {}
    }
  }

  @override
  Future<List<HabitatAlarm>> getScheduledAlarms() async {
    return _scheduledAlarms.values.toList();
  }
}

class WebAlarmService implements PlatformAlarmService {
  final StreamController<NativeAlarmEvent> _eventController =
      StreamController<NativeAlarmEvent>.broadcast();
  final Map<String, HabitatAlarm> _scheduledAlarms = {};

  @override
  Stream<NativeAlarmEvent> get alarmEvents => _eventController.stream;

  @override
  void handleColdStartEvent(NativeAlarmEvent event) {
    _eventController.add(event);
  }

  @override
  Future<bool> requestPermission() async {
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
  Future<void> stopSiren() async {}

  @override
  Future<void> cancelAll() async {
    _scheduledAlarms.clear();
  }

  @override
  Future<List<HabitatAlarm>> getScheduledAlarms() async {
    return _scheduledAlarms.values.toList();
  }
}
