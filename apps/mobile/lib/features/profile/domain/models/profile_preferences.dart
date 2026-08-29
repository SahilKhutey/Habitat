// Habitat Profile General Preferences Domain Model
import 'package:flutter/foundation.dart';

@immutable
class ProfilePreferencesModel {
  final String language;
  final bool timeFormat24h;
  final bool weekStartsOnMonday;
  final String defaultTaskView;
  final String defaultProgressRange;

  const ProfilePreferencesModel({
    this.language = 'English',
    this.timeFormat24h = false,
    this.weekStartsOnMonday = true,
    this.defaultTaskView = 'List',
    this.defaultProgressRange = 'Today',
  });

  ProfilePreferencesModel copyWith({
    String? language,
    bool? timeFormat24h,
    bool? weekStartsOnMonday,
    String? defaultTaskView,
    String? defaultProgressRange,
  }) =>
      ProfilePreferencesModel(
        language: language ?? this.language,
        timeFormat24h: timeFormat24h ?? this.timeFormat24h,
        weekStartsOnMonday: weekStartsOnMonday ?? this.weekStartsOnMonday,
        defaultTaskView: defaultTaskView ?? this.defaultTaskView,
        defaultProgressRange: defaultProgressRange ?? this.defaultProgressRange,
      );

  Map<String, dynamic> toMap() => {
        'language': language,
        'timeFormat24h': timeFormat24h,
        'weekStartsOnMonday': weekStartsOnMonday,
        'defaultTaskView': defaultTaskView,
        'defaultProgressRange': defaultProgressRange,
      };

  factory ProfilePreferencesModel.fromMap(Map<String, dynamic> map) => ProfilePreferencesModel(
        language: map['language'] ?? 'English',
        timeFormat24h: map['timeFormat24h'] ?? false,
        weekStartsOnMonday: map['weekStartsOnMonday'] ?? true,
        defaultTaskView: map['defaultTaskView'] ?? 'List',
        defaultProgressRange: map['defaultProgressRange'] ?? 'Today',
      );
}
