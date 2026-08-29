// Habitat Daily Progress Summary Domain Model
import 'package:flutter/foundation.dart';

@immutable
class DailyProgressSummaryModel {
  final DateTime date;
  final int scheduledCount;
  final int completedCount;
  final int missedCount;
  final int failedCount;
  final List<String> completedTaskTitles;
  final bool hasData; // Distinction: true = scheduled activity existed; false = no data / fresh

  const DailyProgressSummaryModel({
    required this.date,
    required this.scheduledCount,
    required this.completedCount,
    this.missedCount = 0,
    this.failedCount = 0,
    this.completedTaskTitles = const [],
    required this.hasData,
  });

  double get completionRatio =>
      scheduledCount > 0 ? (completedCount / scheduledCount).clamp(0.0, 1.0) : 0.0;

  int get completionPercentage => (completionRatio * 100).round();

  String get dayName => switch (date.weekday) {
        1 => 'Mon',
        2 => 'Tue',
        3 => 'Wed',
        4 => 'Thu',
        5 => 'Fri',
        6 => 'Sat',
        7 => 'Sun',
        _ => 'Day',
      };
}
