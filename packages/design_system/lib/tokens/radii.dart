// Habitat Soft Architectural Geometry & Shape Language
import 'package:flutter/material.dart';

class AppRadii {
  static const double none = 0.0;
  static const double button = 14.0;      // 14-16px
  static const double input = 14.0;       // 14px
  static const double card = 18.0;        // 16-20px
  static const double modal = 24.0;       // 24px
  static const double heroCard = 26.0;    // 24-28px
  static const double circular = 999.0;

  static const BorderRadius radiusButton = BorderRadius.all(Radius.circular(button));
  static const BorderRadius radiusInput = BorderRadius.all(Radius.circular(input));
  static const BorderRadius radiusCard = BorderRadius.all(Radius.circular(card));
  static const BorderRadius radiusModal = BorderRadius.all(Radius.circular(modal));
  static const BorderRadius radiusHeroCard = BorderRadius.all(Radius.circular(heroCard));
  static const BorderRadius radiusCircular = BorderRadius.all(Radius.circular(circular));

  // Legacy backwards compatibility aliases
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 18.0;
  static const double extraLarge = 26.0;

  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(small));
  static const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius radiusLarge = radiusCard;
  static const BorderRadius radiusExtraLarge = radiusHeroCard;
}
