// Habitat Health Master Summary Domain Model
import 'package:flutter/foundation.dart';
import 'meal_entry.dart';
import 'nap_entry.dart';
import 'water_entry.dart';

@immutable
class HealthSummaryModel {
  final DateTime date;
  final WaterSummaryModel water;
  final MealSummaryModel meals;
  final NapSummaryModel nap;

  const HealthSummaryModel({
    required this.date,
    required this.water,
    required this.meals,
    required this.nap,
  });

  bool get isDayActive =>
      water.consumedMilliliters > 0 ||
      meals.loggedCount > 0 ||
      nap.totalMinutes > 0 ||
      nap.isRunning;
}
