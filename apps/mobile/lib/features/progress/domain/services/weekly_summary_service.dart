// Habitat Weekly Summary Service
import '../models/daily_summary.dart';
import '../models/weekly_summary.dart';
import 'daily_summary_service.dart';

class WeeklySummaryService {
  final DailySummaryService _dailyService;

  WeeklySummaryService(this._dailyService);

  WeeklyProgressSummaryModel getWeeklySummary([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    final monday = ref.subtract(Duration(days: ref.weekday - 1));

    final days = <DailyProgressSummaryModel>[];
    int totalCompleted = 0;
    int totalMissed = 0;
    double percentageSum = 0.0;
    int daysWithDataCount = 0;

    String bestDay = 'Mon';
    int bestScore = -1;
    String lowestDay = 'Sun';
    int lowestScore = 101;

    for (int i = 0; i < 7; i++) {
      final date = DateTime(monday.year, monday.month, monday.day + i);
      final daily = _dailyService.getDailySummary(date);
      days.add(daily);

      totalCompleted += daily.completedCount;
      totalMissed += daily.missedCount;

      if (daily.hasData) {
        percentageSum += daily.completionPercentage;
        daysWithDataCount++;

        if (daily.completionPercentage > bestScore) {
          bestScore = daily.completionPercentage;
          bestDay = daily.dayName;
        }
        if (daily.completionPercentage < lowestScore) {
          lowestScore = daily.completionPercentage;
          lowestDay = daily.dayName;
        }
      }
    }

    final avgPercentage = daysWithDataCount > 0 ? (percentageSum / daysWithDataCount) : 0.0;

    return WeeklyProgressSummaryModel(
      startDate: monday,
      endDate: monday.add(const Duration(days: 6)),
      days: days,
      averageCompletionPercentage: avgPercentage,
      totalCompleted: totalCompleted,
      totalMissed: totalMissed,
      bestDay: bestScore >= 0 ? bestDay : 'Mon',
      lowestDay: lowestScore <= 100 ? lowestDay : 'Sun',
    );
  }
}
