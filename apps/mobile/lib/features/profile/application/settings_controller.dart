// Habitat Settings Application Controller
import 'package:flutter/foundation.dart';
import '../../../database/local_database.dart';
import '../domain/models/appearance_settings.dart';
import '../domain/models/notification_settings.dart';
import '../domain/models/profile_preferences.dart';
import '../domain/services/settings_service.dart';

class SettingsController extends ChangeNotifier {
  final SettingsService _settingsService;
  final LocalDatabase _database;

  late ProfilePreferencesModel preferences;
  late NotificationSettingsModel notifications;
  late AppearanceSettingsModel appearance;

  SettingsController({
    required SettingsService settingsService,
    required LocalDatabase database,
  })  : _settingsService = settingsService,
        _database = database {
    _load();
    _database.changes.addListener(_onDataChanged);
  }

  void _load() {
    preferences = _settingsService.getPreferences();
    notifications = _settingsService.getNotificationSettings();
    appearance = _settingsService.getAppearanceSettings();
  }

  void updatePreferences(ProfilePreferencesModel newPrefs) {
    _settingsService.updatePreferences(newPrefs);
  }

  void updateNotificationSettings(NotificationSettingsModel newNotifs) {
    _settingsService.updateNotificationSettings(newNotifs);
  }

  void updateAppearance(AppearanceSettingsModel newApp) {
    _settingsService.updateAppearanceSettings(newApp);
  }

  void _onDataChanged() {
    _load();
    notifyListeners();
  }

  @override
  void dispose() {
    _database.changes.removeListener(_onDataChanged);
    super.dispose();
  }
}
