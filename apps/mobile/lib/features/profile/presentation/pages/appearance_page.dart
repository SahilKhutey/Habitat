// Habitat Appearance & Accessibility Settings Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../domain/models/appearance_settings.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/services/settings_service.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  late final SettingsService _settingsService;
  late AppearanceSettingsModel _appearance;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService(ProfileRepository(LocalDatabase.instance));
    _appearance = _settingsService.getAppearanceSettings();
  }

  void _update(AppearanceSettingsModel updated) {
    setState(() => _appearance = updated);
    _settingsService.updateAppearanceSettings(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('APPEARANCE'),
        backgroundColor: HabitatTheme.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SettingsSection(
              title: 'THEME MODE',
              children: [
                _buildThemeTile('System Default', ThemeModePreference.system, Icons.brightness_auto),
                _buildThemeTile('Dark Theme (Botanical Obsidian)', ThemeModePreference.dark, Icons.dark_mode_outlined),
                _buildThemeTile('Light Theme', ThemeModePreference.light, Icons.light_mode_outlined),
              ],
            ),
            SettingsSection(
              title: 'ACCESSIBILITY PREFERENCES',
              children: [
                SettingsTile(
                  icon: Icons.speed,
                  title: 'Reduce Motion',
                  subtitle: 'Minimizes animated HUD transitions',
                  toggleValue: _appearance.reduceMotion,
                  onToggleChanged: (val) => _update(_appearance.copyWith(reduceMotion: val)),
                ),
                SettingsTile(
                  icon: Icons.contrast,
                  title: 'High Contrast Mode',
                  subtitle: 'Enhances borders and card separation',
                  toggleValue: _appearance.highContrast,
                  onToggleChanged: (val) => _update(_appearance.copyWith(highContrast: val)),
                ),
                SettingsTile(
                  icon: Icons.text_fields,
                  title: 'Larger Text Display',
                  subtitle: 'Increases readability scale across HUDs',
                  toggleValue: _appearance.largerText,
                  onToggleChanged: (val) => _update(_appearance.copyWith(largerText: val)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTile(String label, ThemeModePreference pref, IconData icon) {
    final isSelected = _appearance.themeMode == pref;

    return ListTile(
      leading: Icon(icon, color: isSelected ? HabitatTheme.growthGreen : HabitatTheme.textMuted),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: HabitatTheme.fontHeading,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? Colors.white : HabitatTheme.textSecondary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: HabitatTheme.growthGreen, size: 20)
          : null,
      onTap: () => _update(_appearance.copyWith(themeMode: pref)),
    );
  }
}
