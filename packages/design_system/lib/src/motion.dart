// Habitat Kinetic Animation & Motion Timing Tokens
import 'package:flutter/material.dart';

class HabitatMotion {
  // Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 350);
  static const Duration deliberate = Duration(milliseconds: 500);
  static const Duration sirenPulse = Duration(milliseconds: 800);

  // Curves
  static const Curve snap = Curves.easeOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve smooth = Curves.easeInOutQuart;
}
