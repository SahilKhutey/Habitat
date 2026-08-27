// Standardized Motion and Animation Helpers
import 'package:flutter/material.dart';
import '../tokens/durations.dart';

class AppMotion {
  static const Duration instant = AppDurations.instant;
  static const Duration fast = AppDurations.fast;
  static const Duration normal = AppDurations.normal;
  static const Duration slow = AppDurations.slow;

  static const Curve snap = Curves.easeOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve smooth = Curves.easeInOutQuart;
}
