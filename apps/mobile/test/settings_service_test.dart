// Habitat Settings Service Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/profile/domain/models/appearance_settings.dart';
import 'package:habitat_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:habitat_mobile/features/profile/domain/services/settings_service.dart';

void main() {
  late LocalDatabase db;
  late SettingsService settingsService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    settingsService = SettingsService(ProfileRepository(db));
  });

  group('SettingsService Unit Tests', () {
    test('preferences getter and updater', () {
      var prefs = settingsService.getPreferences();
      expect(prefs.timeFormat24h, isFalse);

      settingsService.updatePreferences(
          prefs.copyWith(timeFormat24h: true, defaultTaskView: 'Timeline'));

      prefs = settingsService.getPreferences();
      expect(prefs.timeFormat24h, isTrue);
      expect(prefs.defaultTaskView, equals('Timeline'));
    });

    test('notification settings getter and updater', () {
      var notifs = settingsService.getNotificationSettings();
      expect(notifs.quietHoursEnabled, isFalse);

      settingsService
          .updateNotificationSettings(notifs.copyWith(quietHoursEnabled: true));

      notifs = settingsService.getNotificationSettings();
      expect(notifs.quietHoursEnabled, isTrue);
    });

    test('appearance settings getter and updater', () {
      var app = settingsService.getAppearanceSettings();
      expect(app.themeMode, equals(ThemeModePreference.system));

      settingsService.updateAppearanceSettings(app.copyWith(
          themeMode: ThemeModePreference.dark, highContrast: true));

      app = settingsService.getAppearanceSettings();
      expect(app.themeMode, equals(ThemeModePreference.dark));
      expect(app.highContrast, isTrue);
    });
  });
}
