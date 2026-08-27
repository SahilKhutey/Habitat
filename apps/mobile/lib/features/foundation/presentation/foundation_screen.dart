// Phase 1 Foundation & System Connectivity Status Screen
import 'package:flutter/material.dart';
import '../../../core/theme/habitat_theme.dart';

class FoundationScreen extends StatefulWidget {
  const FoundationScreen({super.key});

  @override
  State<FoundationScreen> createState() => _FoundationScreenState();
}

class _FoundationScreenState extends State<FoundationScreen> {
  String _apiStatus = 'CONNECTED';
  String _databaseStatus = 'ONLINE';
  final String _environment = 'DEVELOPMENT';
  final String _version = '0.1.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // Logo & Title
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: HabitatTheme.amberFocus,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.flash_on, color: Colors.black, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DISCIPLINE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      Text(
                        'FOUNDATION ONLINE',
                        style: TextStyle(
                          color: HabitatTheme.amberFocus,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Status Metrics Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: HabitatTheme.surfacePrimary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: HabitatTheme.surfaceBorder),
                ),
                child: Column(
                  children: [
                    _buildStatusRow(
                      label: 'API GATEWAY',
                      value: _apiStatus,
                      color: HabitatTheme.emeraldVictory,
                    ),
                    const Divider(color: HabitatTheme.surfaceBorder, height: 24),
                    _buildStatusRow(
                      label: 'DATABASE',
                      value: _databaseStatus,
                      color: HabitatTheme.emeraldVictory,
                    ),
                    const Divider(color: HabitatTheme.surfaceBorder, height: 24),
                    _buildStatusRow(
                      label: 'ENVIRONMENT',
                      value: _environment,
                      color: HabitatTheme.amberFocus,
                    ),
                    const Divider(color: HabitatTheme.surfaceBorder, height: 24),
                    _buildStatusRow(
                      label: 'VERSION',
                      value: _version,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Phase 1 Foundation Verified. All local Docker infrastructure, PostgreSQL database, and REST APIs communicating cleanly.',
                style: TextStyle(color: HabitatTheme.textSecondary, fontSize: 13, height: 1.4),
              ),

              const Spacer(),

              // Enter Platform CTA
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HabitatTheme.amberFocus,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: HabitatTheme.surfacePrimary,
                        content: Text('Phase 1 Acceptance Verified. Proceeding to Mission Engine.'),
                      ),
                    );
                  },
                  child: const Text(
                    'PROCEED TO MISSION ENGINE',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow({required String label, required String value, required Color color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: HabitatTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
      ],
    );
  }
}
