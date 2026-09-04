// Habitat About & Application Information Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('ABOUT HABITAT'),
        backgroundColor: HabitatTheme.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // App Logo & Version
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: HabitatTheme.growthGreen.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: HabitatTheme.habitatGreen,
                    ),
                    child: const Icon(Icons.eco,
                        color: HabitatTheme.growthGreen, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'HABITAT',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Build the life you want to live.',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontBody,
                      fontSize: 13,
                      color: HabitatTheme.youngLeaf,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Version 1.0.0 (Production Release)',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontBody,
                      fontSize: 11,
                      color: HabitatTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SettingsSection(
              title: 'LEGAL & ARCHITECTURE',
              children: [
                SettingsTile(
                  icon: Icons.code,
                  title: 'Open Source Licenses',
                  subtitle: 'Flutter, Vitest, MoveNet & SQLite ecosystem',
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Habitat Platform',
                      applicationVersion: '1.0.0',
                    );
                  },
                ),
                SettingsTile(
                  icon: Icons.policy_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Local-first zero-telemetry architecture',
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.gavel_outlined,
                  title: 'Terms of Service',
                  subtitle: 'User commitment and integrity contract',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
