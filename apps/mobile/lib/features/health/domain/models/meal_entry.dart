// Habitat Meal Domain Models
import 'package:flutter/foundation.dart';

enum MealType {
  breakfast,
  lunch,
  snack,
  dinner,
}

enum MealStatus {
  notLogged,
  logged,
  skipped,
}

@immutable
class MealEntryModel {
  final String id;
  final MealType type;
  final DateTime recordedAt;
  final String? notes;
  final MealStatus status;

  const MealEntryModel({
    required this.id,
    required this.type,
    required this.recordedAt,
    this.notes,
    this.status = MealStatus.logged,
  });

  String get typeDisplayName => switch (type) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.snack => 'Snacks',
        MealType.dinner => 'Dinner',
      };
}

@immutable
class MealSummaryModel {
  final int loggedCount;
  final int targetCount;
  final List<MealEntryModel> entries;

  const MealSummaryModel({
    required this.loggedCount,
    this.targetCount = 4,
    this.entries = const [],
  });

  bool get hasBreakfast => entries.any((e) => e.type == MealType.breakfast);
  bool get hasLunch => entries.any((e) => e.type == MealType.lunch);
  bool get hasSnack => entries.any((e) => e.type == MealType.snack);
  bool get hasDinner => entries.any((e) => e.type == MealType.dinner);

  MealEntryModel? get breakfastEntry => _findFirst(MealType.breakfast);
  MealEntryModel? get lunchEntry => _findFirst(MealType.lunch);
  MealEntryModel? get snackEntry => _findFirst(MealType.snack);
  MealEntryModel? get dinnerEntry => _findFirst(MealType.dinner);

  MealEntryModel? _findFirst(MealType type) {
    for (final e in entries) {
      if (e.type == type) return e;
    }
    return null;
  }
}
