// Habitat Monthly Progress Summary Domain Model
import 'package:flutter/foundation.dart';
import 'weekly_summary.dart';

@immutable
class MonthlyProgressSummaryModel {
  final int year;
  final int month;
  final List<WeeklyProgressSummaryModel> weeks;
  final double averageCompletionPercentage;
  final int totalCompleted;
  final int totalMissed;
  final String bestWeek;

  const MonthlyProgressSummaryModel({
    required this.year,
    required this.month,
    required this.weeks,
    required this.averageCompletionPercentage,
    required this.totalCompleted,
    required this.totalMissed,
    this.bestWeek = 'Week 1',
  });

  String get monthName => switch (month) {
        1 => 'January',
        2 => 'February',
        3 => 'March',
        4 => 'April',
        5 => 'May',
        6 => 'June',
        7 => 'July',
        8 => 'August',
        9 => 'September',
        10 => 'October',
        11 => 'November',
        12 => 'December',
        _ => 'Month',
      };
}
