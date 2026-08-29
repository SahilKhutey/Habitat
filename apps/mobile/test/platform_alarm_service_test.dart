// Habitat Platform Alarm Service Unit Tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/core/platform/alarm/platform_alarm_service.dart';
import 'package:habitat_mobile/features/alarms/domain/services/alarm_scheduler.dart';

void main() {
  group('PlatformAlarmService Multi-Platform Tests', () {
    test('AndroidAlarmService schedules, retrieves, and cancels alarms', () async {
      final androidService = AndroidAlarmService();
      const alarm = HabitatAlarm(
        id: 'alarm_001',
        taskId: 'task_001',
        title: 'Morning Pushup Alarm',
        time: TimeOfDay(hour: 6, minute: 30),
      );

      await androidService.schedule(alarm);
      var scheduled = await androidService.getScheduledAlarms();
      expect(scheduled.length, equals(1));
      expect(scheduled.first.title, equals('Morning Pushup Alarm'));

      await androidService.cancel('alarm_001');
      scheduled = await androidService.getScheduledAlarms();
      expect(scheduled.isEmpty, isTrue);
    });

    test('IOSAlarmService requests permission and schedules reminders', () async {
      final iosService = IOSAlarmService();
      final hasPerm = await iosService.requestPermission();
      expect(hasPerm, isTrue);

      const alarm = HabitatAlarm(
        id: 'alarm_ios_01',
        taskId: 'task_002',
        title: 'Bedtime Journal',
        time: TimeOfDay(hour: 22, minute: 0),
      );

      await iosService.schedule(alarm);
      final scheduled = await iosService.getScheduledAlarms();
      expect(scheduled.length, equals(1));
    });

    test('WebAlarmService provides browser fallback without throwing', () async {
      final webService = WebAlarmService();
      const alarm = HabitatAlarm(
        id: 'alarm_web_01',
        taskId: 'task_003',
        title: 'Drink Water',
        time: TimeOfDay(hour: 14, minute: 0),
      );

      await webService.schedule(alarm);
      final scheduled = await webService.getScheduledAlarms();
      expect(scheduled.length, equals(1));
      expect(scheduled.first.id, equals('alarm_web_01'));
    });
  });
}
