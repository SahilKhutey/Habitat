// Habitat General Preferences Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../domain/models/profile_preferences.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/services/settings_service.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  late final SettingsService _settingsService;
  late ProfilePreferencesModel _preferences;

  @override
  void initState() {
    super.initState();
    _settingsService =
        SettingsService(ProfileRepository(LocalDatabase.instance));
    _preferences = _settingsService.getPreferences();
  }

  void _update(ProfilePreferencesModel updated) {
    setState(() => _preferences = updated);
    _settingsService.updatePreferences(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('GENERAL PREFERENCES'),
        backgroundColor: HabitatTheme.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SettingsSection(
              title: 'TIME & CALENDAR',
              children: [
                SettingsTile(
                  icon: Icons.schedule,
                  title: '24-Hour Time Format',
                  subtitle: _preferences.timeFormat24h
                      ? 'e.g. 14:30'
                      : 'e.g. 02:30 PM',
                  toggleValue: _preferences.timeFormat24h,
                  onToggleChanged: (val) =>
                      _update(_preferences.copyWith(timeFormat24h: val)),
                ),
                SettingsTile(
                  icon: Icons.calendar_today_outlined,
                  title: 'Week Starts on Monday',
                  subtitle: _preferences.weekStartsOnMonday
                      ? 'Monday to Sunday'
                      : 'Sunday to Saturday',
                  toggleValue: _preferences.weekStartsOnMonday,
                  onToggleChanged: (val) =>
                      _update(_preferences.copyWith(weekStartsOnMonday: val)),
                ),
              ],
            ),
            SettingsSection(
              title: 'DEFAULTS',
              children: [
                SettingsTile(
                  icon: Icons.language,
                  title: 'Application Language',
                  subtitle: _preferences.language,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('English is the active system language.')),
                    );
                  },
                ),
                SettingsTile(
                  icon: Icons.view_agenda_outlined,
                  title: 'Default Task View',
                  subtitle: _preferences.defaultTaskView,
                  onTap: () {
                    final next = _preferences.defaultTaskView == 'List'
                        ? 'Timeline'
                        : 'List';
                    _update(_preferences.copyWith(defaultTaskView: next));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
