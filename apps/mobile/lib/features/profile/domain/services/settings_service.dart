// Habitat General Settings & Preferences Service
import '../models/appearance_settings.dart';
import '../models/notification_settings.dart';
import '../models/profile_preferences.dart';
import '../repositories/profile_repository.dart';

class SettingsService {
  final ProfileRepository _repository;

  SettingsService(this._repository);

  // 1. Preferences
  ProfilePreferencesModel getPreferences() {
    return ProfilePreferencesModel.fromMap(_repository.getPreferences());
  }

  void updatePreferences(ProfilePreferencesModel preferences) {
    _repository.setPreferences(preferences.toMap());
  }

  // 2. Notifications
  NotificationSettingsModel getNotificationSettings() {
    return NotificationSettingsModel.fromMap(
        _repository.getNotificationSettings());
  }

  void updateNotificationSettings(NotificationSettingsModel settings) {
    _repository.setNotificationSettings(settings.toMap());
  }

  // 3. Appearance
  AppearanceSettingsModel getAppearanceSettings() {
    return AppearanceSettingsModel.fromMap(_repository.getAppearanceSettings());
  }

  void updateAppearanceSettings(AppearanceSettingsModel appearance) {
    _repository.setAppearanceSettings(appearance.toMap());
  }
}
