// Habitat Appearance & Accessibility Settings Domain Model
import 'package:flutter/foundation.dart';

enum ThemeModePreference { system, light, dark }

@immutable
class AppearanceSettingsModel {
  final ThemeModePreference themeMode;
  final bool reduceMotion;
  final bool highContrast;
  final bool largerText;

  const AppearanceSettingsModel({
    this.themeMode = ThemeModePreference.system,
    this.reduceMotion = false,
    this.highContrast = false,
    this.largerText = false,
  });

  AppearanceSettingsModel copyWith({
    ThemeModePreference? themeMode,
    bool? reduceMotion,
    bool? highContrast,
    bool? largerText,
  }) =>
      AppearanceSettingsModel(
        themeMode: themeMode ?? this.themeMode,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        highContrast: highContrast ?? this.highContrast,
        largerText: largerText ?? this.largerText,
      );

  Map<String, dynamic> toMap() => {
        'themeMode': themeMode.name,
        'reduceMotion': reduceMotion,
        'highContrast': highContrast,
        'largerText': largerText,
      };

  factory AppearanceSettingsModel.fromMap(Map<String, dynamic> map) => AppearanceSettingsModel(
        themeMode: ThemeModePreference.values.firstWhere(
          (m) => m.name == map['themeMode'],
          orElse: () => ThemeModePreference.system,
        ),
        reduceMotion: map['reduceMotion'] ?? false,
        highContrast: map['highContrast'] ?? false,
        largerText: map['largerText'] ?? false,
      );
}
