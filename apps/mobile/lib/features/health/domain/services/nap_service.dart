// Habitat Nap Service
import '../models/nap_entry.dart';
import '../repositories/health_repository.dart';

class NapService {
  final HealthRepository _repository;

  NapService(this._repository);

  NapEntryModel startNap({DateTime? startedAt}) {
    return _repository.startNap(startedAt: startedAt);
  }

  void stopNap({DateTime? endedAt}) {
    _repository.stopNap(endedAt: endedAt);
  }

  NapEntryModel? getCurrentNap([DateTime? date]) {
    final day = date ?? DateTime.now();
    final naps = _repository.getNapEntries(day);
    for (final nap in naps) {
      if (nap.isRunning) return nap;
    }
    return null;
  }

  NapSummaryModel getTodaySummary([DateTime? date]) {
    final day = date ?? DateTime.now();
    final entries = _repository.getNapEntries(day);
    final isRunning = entries.any((e) => e.isRunning);
    final activeNap = getCurrentNap(day);
    final totalMinutes =
        entries.fold(0, (total, e) => total + e.durationMinutes);

    return NapSummaryModel(
      totalMinutes: totalMinutes,
      isRunning: isRunning,
      activeNap: activeNap,
      todayNaps: entries,
    );
  }

  List<NapSummaryModel> getHistory([int days = 7]) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final date = now.subtract(Duration(days: i));
      return getTodaySummary(date);
    });
  }
}
