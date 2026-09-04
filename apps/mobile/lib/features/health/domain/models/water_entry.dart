// Habitat Water Intake Domain Models
import 'package:flutter/foundation.dart';

@immutable
class WaterEntryModel {
  final String id;
  final int milliliters;
  final DateTime timestamp;
  final String source; // 'preset', 'custom', 'task_action'

  const WaterEntryModel({
    required this.id,
    required this.milliliters,
    required this.timestamp,
    this.source = 'preset',
  });
}

@immutable
class WaterSummaryModel {
  final int consumedMilliliters;
  final int targetMilliliters;
  final List<WaterEntryModel> entries;

  const WaterSummaryModel({
    required this.consumedMilliliters,
    this.targetMilliliters = 2000,
    this.entries = const [],
  });

  double get progressPercentage =>
      (consumedMilliliters / targetMilliliters).clamp(0.0, 1.0);

  int get remainingMilliliters =>
      (targetMilliliters - consumedMilliliters).clamp(0, targetMilliliters);

  double get consumedLiters => consumedMilliliters / 1000.0;

  double get targetLiters => targetMilliliters / 1000.0;
}
