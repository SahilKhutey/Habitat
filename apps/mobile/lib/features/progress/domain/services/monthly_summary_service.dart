// Habitat Monthly Summary Service
import '../models/monthly_summary.dart';
import '../models/weekly_summary.dart';
import 'weekly_summary_service.dart';

class MonthlySummaryService {
  final WeeklySummaryService _weeklyService;

  MonthlySummaryService(this._weeklyService);

  MonthlyProgressSummaryModel getMonthlySummary([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    final firstDay = DateTime(ref.year, ref.month, 1);

    final weeks = <WeeklyProgressSummaryModel>[];
    int totalCompleted = 0;
    int totalMissed = 0;
    double percentageSum = 0.0;

    String bestWeek = 'Week 1';
    double bestScore = -1.0;

    for (int w = 0; w < 4; w++) {
      final weekDate = firstDay.add(Duration(days: w * 7));
      final weekly = _weeklyService.getWeeklySummary(weekDate);
      weeks.add(weekly);

      totalCompleted += weekly.totalCompleted;
      totalMissed += weekly.totalMissed;
      percentageSum += weekly.averageCompletionPercentage;

      if (weekly.averageCompletionPercentage > bestScore) {
        bestScore = weekly.averageCompletionPercentage;
        bestWeek = 'Week ${w + 1}';
      }
    }

    final avgPercentage = weeks.isNotEmpty ? (percentageSum / weeks.length) : 0.0;

    return MonthlyProgressSummaryModel(
      year: ref.year,
      month: ref.month,
      weeks: weeks,
      averageCompletionPercentage: avgPercentage,
      totalCompleted: totalCompleted,
      totalMissed: totalMissed,
      bestWeek: bestWeek,
    );
  }
}
