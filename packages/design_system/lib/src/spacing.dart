// Habitat Strict 4pt Grid & Radii Tokens
import 'package:flutter/material.dart';

class HabitatSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double s = 12.0;
  static const double m = 16.0;
  static const double l = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double huge = 48.0;
}

class HabitatRadii {
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 20.0;
  static const double pill = 999.0;

  static const BorderRadius radiusS = BorderRadius.all(Radius.circular(s));
  static const BorderRadius radiusM = BorderRadius.all(Radius.circular(m));
  static const BorderRadius radiusL = BorderRadius.all(Radius.circular(l));
  static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(pill));
}
