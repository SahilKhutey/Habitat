// Habitat Design System - Motion & Animation Tokens
import 'package:flutter/material.dart';

abstract final class HabitatMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve sharpCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.easeOutBack;
}
