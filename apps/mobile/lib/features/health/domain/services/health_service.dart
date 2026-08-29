// Habitat Health Master Service & Orchestrator
import '../models/health_summary.dart';
import 'meal_service.dart';
import 'nap_service.dart';
import 'water_service.dart';

class HealthService {
  final WaterService waterService;
  final MealService mealService;
  final NapService napService;

  HealthService({
    required this.waterService,
    required this.mealService,
    required this.napService,
  });

  HealthSummaryModel getTodaySummary([DateTime? date]) {
    final day = date ?? DateTime.now();
    return HealthSummaryModel(
      date: day,
      water: waterService.getTodaySummary(day),
      meals: mealService.getTodaySummary(day),
      nap: napService.getTodaySummary(day),
    );
  }

  List<HealthSummaryModel> getMultiDayHistory([int days = 7]) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final date = now.subtract(Duration(days: i));
      return getTodaySummary(date);
    });
  }
}
