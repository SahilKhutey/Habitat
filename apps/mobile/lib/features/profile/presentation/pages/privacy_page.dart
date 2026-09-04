// Habitat Privacy & Local Data Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../domain/models/privacy_settings.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/services/privacy_service.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import 'data_storage_page.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  late final PrivacyService _privacyService;
  late PrivacySettingsModel _privacy;

  @override
  void initState() {
    super.initState();
    _privacyService = PrivacyService(ProfileRepository(LocalDatabase.instance));
    _privacy = _privacyService.getPrivacySettings();
  }

  void _update(PrivacySettingsModel updated) {
    setState(() => _privacy = updated);
    _privacyService.updatePrivacySettings(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('PRIVACY & LOCAL DATA'),
        backgroundColor: HabitatTheme.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Local-First Guarantee Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: HabitatTheme.growthGreen.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_clock_outlined,
                          color: HabitatTheme.growthGreen, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'LOCAL-FIRST GUARANTEE',
                        style: TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: HabitatTheme.youngLeaf,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Your Habitat tasks, routines, alarms, hydration records, and nap history are stored strictly on this device in an offline database. No biometric or media proof is ever transmitted without explicit permission.',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontBody,
                      fontSize: 12,
                      color: HabitatTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SettingsSection(
              title: 'TELEMETRY & SHARING',
              children: [
                SettingsTile(
                  icon: Icons.analytics_outlined,
                  title: 'Anonymous Usage Analytics',
                  subtitle:
                      'Helps improve algorithm reliability without tracking personal info',
                  toggleValue: _privacy.analyticsEnabled,
                  onToggleChanged: (val) =>
                      _update(_privacy.copyWith(analyticsEnabled: val)),
                ),
                SettingsTile(
                  icon: Icons.share_outlined,
                  title: 'Cross-Device Data Syncing',
                  subtitle:
                      'Sync discipline state with optional trusted peer nodes',
                  toggleValue: _privacy.dataSharingEnabled,
                  onToggleChanged: (val) =>
                      _update(_privacy.copyWith(dataSharingEnabled: val)),
                ),
              ],
            ),

            SettingsSection(
              title: 'DATA CONTROLS',
              children: [
                SettingsTile(
                  icon: Icons.folder_shared_outlined,
                  title: 'Manage Stored Data & Backups',
                  subtitle: 'Export or inspect local SQLite files',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const DataStoragePage()),
                    );
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
