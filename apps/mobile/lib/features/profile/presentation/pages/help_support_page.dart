// Habitat Help, Support & Diagnostics Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../widgets/settings_section.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('HELP & SUPPORT'),
        backgroundColor: HabitatTheme.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Diagnostics Status Center
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: HabitatTheme.growthGreen.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.monitor_heart_outlined,
                          color: HabitatTheme.growthGreen, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'CORE PLATFORM DIAGNOSTICS',
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
                  const SizedBox(height: 14),
                  _buildDiagRow('Local Database Engine',
                      'Operational (SQLite First)', true),
                  _buildDiagRow('Native Alarm Scheduler',
                      'Operational (Exact Alarm API)', true),
                  _buildDiagRow('MoveNet Vision Verifier',
                      'Operational (TFJS Engine)', true),
                  _buildDiagRow(
                      'Grace Vault System', 'Operational (Token Guard)', true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SettingsSection(
              title: 'FREQUENTLY ASKED QUESTIONS',
              children: [
                _buildFaqTile('How does Habit verification work?',
                    'Habitat uses on-device camera proof or resistance countdowns to confirm that you actually showed up for your commitment.'),
                _buildFaqTile('What happens when my streak is broken?',
                    'Habitat never punishes you. Historical records remain intact, and you can resume right away or use a Grace Token.'),
                _buildFaqTile('Is my data private?',
                    'Yes. All data is kept strictly on your local device without unauthorized cloud transmission.'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagRow(String name, String status, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style: const TextStyle(
                  fontFamily: HabitatTheme.fontBody,
                  fontSize: 12,
                  color: Colors.white)),
          Row(
            children: [
              Text(status,
                  style: TextStyle(
                      fontFamily: HabitatTheme.fontBody,
                      fontSize: 11,
                      color: ok ? HabitatTheme.growthGreen : Colors.redAccent)),
              const SizedBox(width: 6),
              Icon(ok ? Icons.check_circle : Icons.error,
                  color: ok ? HabitatTheme.growthGreen : Colors.redAccent,
                  size: 14),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return ExpansionTile(
      iconColor: HabitatTheme.growthGreen,
      collapsedIconColor: HabitatTheme.textMuted,
      title: Text(
        question,
        style: const TextStyle(
            fontFamily: HabitatTheme.fontHeading,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          child: Text(
            answer,
            style: const TextStyle(
                fontFamily: HabitatTheme.fontBody,
                fontSize: 12,
                color: HabitatTheme.textSecondary,
                height: 1.4),
          ),
        ),
      ],
    );
  }
}
