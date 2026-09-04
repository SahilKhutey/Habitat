// Habitat Profile Repository Layer
import '../../../../database/local_database.dart';

class ProfileRepository {
  final LocalDatabase _database;

  ProfileRepository(this._database);

  LocalUser getProfile() => _database.getOrCreateProfile();

  void updateProfile(
      {required String displayName, required String bio, String? avatarUrl}) {
    _database.updateProfile(
        displayName: displayName, bio: bio, avatarUrl: avatarUrl);
  }

  Map<String, dynamic> getPreferences() => _database.getPreferences();
  void setPreferences(Map<String, dynamic> map) =>
      _database.setPreferences(map);

  Map<String, dynamic> getNotificationSettings() =>
      _database.getNotificationSettings();
  void setNotificationSettings(Map<String, dynamic> map) =>
      _database.setNotificationSettings(map);

  Map<String, dynamic> getAppearanceSettings() =>
      _database.getAppearanceSettings();
  void setAppearanceSettings(Map<String, dynamic> map) =>
      _database.setAppearanceSettings(map);

  Map<String, dynamic> getPrivacySettings() => _database.getPrivacySettings();
  void setPrivacySettings(Map<String, dynamic> map) =>
      _database.setPrivacySettings(map);

  Map<String, dynamic> getSecuritySettings() => _database.getSecuritySettings();
  void setSecuritySettings(Map<String, dynamic> map) =>
      _database.setSecuritySettings(map);

  Map<String, int> getStorageBreakdown() => _database.getStorageBreakdown();

  String exportAllDataAsJson() => _database.exportAllDataAsJson();

  void resetAllData() => _database.resetAllData();
}
