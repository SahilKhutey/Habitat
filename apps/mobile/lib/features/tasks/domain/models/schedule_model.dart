// Habitat Schedule Domain Model
import 'package:flutter/foundation.dart';

enum ScheduleRecurrenceType {
  oneTime,
  daily,
  weekdays,
  weekends,
  customDays,
}

@immutable
class TaskScheduleModel {
  final ScheduleRecurrenceType recurrenceType;
  final String timeOfDay; // HH:mm format, e.g. "07:00"
  final List<int> repeatDays; // 1 = Monday, 7 = Sunday
  final DateTime? startDate;
  final DateTime? endDate;
  final String timezone;

  const TaskScheduleModel({
    this.recurrenceType = ScheduleRecurrenceType.daily,
    this.timeOfDay = '07:00',
    this.repeatDays = const [1, 2, 3, 4, 5, 6, 7],
    this.startDate,
    this.endDate,
    this.timezone = 'UTC',
  });

  String get recurrenceDisplayName => switch (recurrenceType) {
        ScheduleRecurrenceType.oneTime => 'One Time',
        ScheduleRecurrenceType.daily => 'Daily',
        ScheduleRecurrenceType.weekdays => 'Weekdays (Mon-Fri)',
        ScheduleRecurrenceType.weekends => 'Weekends (Sat-Sun)',
        ScheduleRecurrenceType.customDays => _formatCustomDays(repeatDays),
      };

  static String _formatCustomDays(List<int> days) {
    if (days.length == 7) return 'Every Day';
    if (days.length == 5 && !days.contains(6) && !days.contains(7)) {
      return 'Weekdays';
    }
    const dayNames = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun'
    };
    return days.map((d) => dayNames[d] ?? '$d').join(', ');
  }
}
