// Habitat Nap Domain Models
import 'package:flutter/foundation.dart';

enum NapStatus {
  idle,
  running,
  completed,
  interrupted,
}

@immutable
class NapEntryModel {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final bool isRunning;

  const NapEntryModel({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.durationMinutes,
    required this.isRunning,
  });
}

@immutable
class NapSummaryModel {
  final int totalMinutes;
  final bool isRunning;
  final NapEntryModel? activeNap;
  final List<NapEntryModel> todayNaps;

  const NapSummaryModel({
    required this.totalMinutes,
    required this.isRunning,
    this.activeNap,
    this.todayNaps = const [],
  });

  String get formattedDuration {
    if (totalMinutes == 0) return '0 min';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '$mins min';
  }
}
