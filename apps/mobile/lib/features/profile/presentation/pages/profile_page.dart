// Habitat Master Profile Hub Screen (Tab 3)
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../application/profile_controller.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/services/privacy_service.dart';
import '../../domain/services/profile_service.dart';
import '../../domain/services/security_service.dart';
import '../../domain/services/settings_service.dart';
import '../widgets/profile_header.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import 'about_page.dart';
import 'appearance_page.dart';
import 'data_storage_page.dart';
import 'edit_profile_page.dart';
import 'help_support_page.dart';
import 'notifications_page.dart';
import 'permissions_page.dart';
import 'preferences_page.dart';
import 'privacy_page.dart';
import 'security_page.dart';

class ProfilePage extends StatefulWidget {
  final ProfileController? controller;

  const ProfilePage({super.key, this.controller});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileController _controller;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      final db = LocalDatabase.instance;
      final repo = ProfileRepository(db);
      _controller = ProfileController(
        profileService: ProfileService(repo),
        settingsService: SettingsService(repo),
        privacyService: PrivacyService(repo),
        securityService: SecurityService(repo),
        database: db,
      );
      _internalController = true;
    }
  }

  @override
  void dispose() {
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final user = _controller.user;

        return Scaffold(
          backgroundColor: HabitatTheme.background,
          appBar: AppBar(
            title: const Text('PROFILE & SETTINGS'),
            backgroundColor: HabitatTheme.background,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Profile Header
                ProfileHeader(
                  user: user,
                  onEdit: () => _openScreen(const EditProfilePage()),
                ),
                const SizedBox(height: 24),

                // 2. Personal Section
                SettingsSection(
                  title: 'PERSONAL',
                  children: [
                    SettingsTile(
                      icon: Icons.person_outline,
                      title: 'Personal Information',
                      subtitle: user.displayName,
                      onTap: () => _openScreen(const EditProfilePage()),
                    ),
                  ],
                ),

                // 3. Preferences Section
                SettingsSection(
                  title: 'PREFERENCES',
                  children: [
                    SettingsTile(
                      icon: Icons.tune,
                      title: 'General Preferences',
                      subtitle: 'Language, Time Format, Week Start',
                      onTap: () => _openScreen(const PreferencesPage()),
                    ),
                    SettingsTile(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      subtitle: 'Task reminders, Alarms, Milestones',
                      onTap: () => _openScreen(const NotificationsPage()),
                    ),
                    SettingsTile(
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      subtitle: 'Theme, Accessibility & Contrast',
                      onTap: () => _openScreen(const AppearancePage()),
                    ),
                  ],
                ),

                // 4. Security & Permissions
                SettingsSection(
                  title: 'SECURITY & PRIVACY',
                  children: [
                    SettingsTile(
                      icon: Icons.shield_outlined,
                      title: 'Privacy & Local Data',
                      subtitle: 'Local-first storage & Analytics controls',
                      onTap: () => _openScreen(const PrivacyPage()),
                    ),
                    SettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Security & App Lock',
                      subtitle: _controller.security.appLockEnabled
                          ? 'Protected'
                          : 'Standard',
                      onTap: () => _openScreen(const SecurityPage()),
                    ),
                    SettingsTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Platform Permissions',
                      subtitle: 'Diagnostics for Alarms, Camera, Push',
                      onTap: () => _openScreen(const PermissionsPage()),
                    ),
                  ],
                ),

                // 5. Data & Storage
                SettingsSection(
                  title: 'DATA CONTROLS',
                  children: [
                    SettingsTile(
                      icon: Icons.folder_open_outlined,
                      title: 'Data & Local Storage',
                      subtitle: 'Export JSON, Backups & Clear Cache',
                      onTap: () => _openScreen(const DataStoragePage()),
                    ),
                  ],
                ),

                // 6. Support & About
                SettingsSection(
                  title: 'SUPPORT',
                  children: [
                    SettingsTile(
                      icon: Icons.help_outline,
                      title: 'Help & Troubleshooting',
                      subtitle: 'FAQ, Guides & Diagnostics check',
                      onTap: () => _openScreen(const HelpSupportPage()),
                    ),
                    SettingsTile(
                      icon: Icons.info_outline,
                      title: 'About Habitat',
                      subtitle: 'v1.0.0 • Architecture & Open Licenses',
                      onTap: () => _openScreen(const AboutPage()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openScreen(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
