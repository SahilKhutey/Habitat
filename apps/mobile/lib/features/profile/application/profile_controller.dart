// Habitat Master Profile Application Controller
import 'package:flutter/foundation.dart';
import '../../../database/local_database.dart';
import '../domain/models/appearance_settings.dart';
import '../domain/models/notification_settings.dart';
import '../domain/models/privacy_settings.dart';
import '../domain/models/profile_preferences.dart';
import '../domain/models/security_settings.dart';
import '../domain/models/user_profile.dart';
import '../domain/services/privacy_service.dart';
import '../domain/services/profile_service.dart';
import '../domain/services/security_service.dart';
import '../domain/services/settings_service.dart';

class ProfileController extends ChangeNotifier {
  final ProfileService _profileService;
  final SettingsService _settingsService;
  final PrivacyService _privacyService;
  final SecurityService _securityService;
  final LocalDatabase _database;

  late UserProfileModel user;
  late ProfilePreferencesModel preferences;
  late NotificationSettingsModel notifications;
  late AppearanceSettingsModel appearance;
  late PrivacySettingsModel privacy;
  late SecuritySettingsModel security;

  ProfileController({
    required ProfileService profileService,
    required SettingsService settingsService,
    required PrivacyService privacyService,
    required SecurityService securityService,
    required LocalDatabase database,
  })  : _profileService = profileService,
        _settingsService = settingsService,
        _privacyService = privacyService,
        _securityService = securityService,
        _database = database {
    _loadState();
    _database.changes.addListener(_onDataChanged);
  }

  void _loadState() {
    user = _profileService.getProfile();
    preferences = _settingsService.getPreferences();
    notifications = _settingsService.getNotificationSettings();
    appearance = _settingsService.getAppearanceSettings();
    privacy = _privacyService.getPrivacySettings();
    security = _securityService.getSecuritySettings();
  }

  void updateProfile(
      {required String displayName, required String bio, String? avatarUrl}) {
    _profileService.updateProfile(
        displayName: displayName, bio: bio, avatarUrl: avatarUrl);
  }

  void updatePreferences(ProfilePreferencesModel newPrefs) {
    _settingsService.updatePreferences(newPrefs);
  }

  void updateNotificationSettings(NotificationSettingsModel newNotifs) {
    _settingsService.updateNotificationSettings(newNotifs);
  }

  void updateAppearance(AppearanceSettingsModel newAppearance) {
    _settingsService.updateAppearanceSettings(newAppearance);
  }

  void updatePrivacy(PrivacySettingsModel newPrivacy) {
    _privacyService.updatePrivacySettings(newPrivacy);
  }

  void updateSecurity(SecuritySettingsModel newSecurity) {
    _securityService.updateSecuritySettings(newSecurity);
  }

  void _onDataChanged() {
    _loadState();
    notifyListeners();
  }

  @override
  void dispose() {
    _database.changes.removeListener(_onDataChanged);
    super.dispose();
  }
}
