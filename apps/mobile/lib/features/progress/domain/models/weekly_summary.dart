// Habitat Weekly Progress Summary Domain Model
import 'package:flutter/foundation.dart';
import 'daily_summary.dart';

@immutable
class WeeklyProgressSummaryModel {
  final DateTime startDate;
  final DateTime endDate;
  final List<DailyProgressSummaryModel> days; // 7 days: Mon -> Sun
  final double averageCompletionPercentage;
  final int totalCompleted;
  final int totalMissed;
  final String bestDay;
  final String lowestDay;

  const WeeklyProgressSummaryModel({
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.averageCompletionPercentage,
    required this.totalCompleted,
    required this.totalMissed,
    this.bestDay = 'Mon',
    this.lowestDay = 'Sun',
  });
}
