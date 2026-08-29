// Habitat Daily Summary Service
import '../models/daily_summary.dart';
import '../repositories/progress_repository.dart';

class DailySummaryService {
  final ProgressRepository _repository;

  DailySummaryService(this._repository);

  DailyProgressSummaryModel getDailySummary(DateTime date) {
    final attempts = _repository.getAttemptsForDay(date);
    final allTasks = _repository.getAllTasks();
    final activeTasks = allTasks.where((t) => t.active).toList();

    final completedAttempts = attempts.where((a) => a.status == 'COMPLETED').toList();
    final failedAttempts = attempts.where((a) => a.status == 'FAILED').toList();

    final completedTitles = <String>[];
    for (final ca in completedAttempts) {
      final task = allTasks.firstWhere(
        (t) => t.id == ca.taskId,
        orElse: () => allTasks.first,
      );
      completedTitles.add(task.title);
    }

    final isToday = _sameDay(date, DateTime.now());
    final scheduledCount = isToday
        ? activeTasks.length
        : attempts.isNotEmpty
            ? attempts.length
            : 0;

    final completedCount = completedAttempts.length;
    final missedCount = (scheduledCount - completedCount).clamp(0, scheduledCount);
    final hasData = attempts.isNotEmpty || (isToday && activeTasks.isNotEmpty);

    return DailyProgressSummaryModel(
      date: date,
      scheduledCount: scheduledCount,
      completedCount: completedCount,
      missedCount: missedCount,
      failedCount: failedAttempts.length,
      completedTaskTitles: completedTitles,
      hasData: hasData,
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
