// Habitat Dedicated Security & App Lock Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../domain/models/security_settings.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/services/security_service.dart';
import '../widgets/security_status.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  late final SecurityService _securityService;
  late SecuritySettingsModel _security;

  @override
  void initState() {
    super.initState();
    _securityService = SecurityService(ProfileRepository(LocalDatabase.instance));
    _security = _securityService.getSecuritySettings();
  }

  void _update(SecuritySettingsModel updated) {
    setState(() => _security = updated);
    _securityService.updateSecuritySettings(updated);
  }

  void _showSetPinDialog() {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HabitatTheme.surfacePrimary,
        title: const Text(
          'CONFIGURE APP PIN',
          style: TextStyle(fontFamily: HabitatTheme.fontHeading, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Enter 4 to 6 digit PIN',
            labelStyle: const TextStyle(color: HabitatTheme.textSecondary),
            filled: true,
            fillColor: HabitatTheme.surfaceSecondary,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: HabitatTheme.surfaceBorder)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: HabitatTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = pinController.text.trim();
              if (pin.length >= 4) {
                _securityService.setPin(pin);
                _update(_security.copyWith(pinCode: pin, appLockEnabled: true));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Security PIN configured! App Lock is now active.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: HabitatTheme.growthGreen, foregroundColor: HabitatTheme.forest),
            child: const Text('Save PIN', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('SECURITY & APP LOCK'),
        backgroundColor: HabitatTheme.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SecurityStatus(security: _security),
            const SizedBox(height: 20),

            SettingsSection(
              title: 'AUTHENTICATION CONTROLS',
              children: [
                SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Require App Lock on Launch',
                  subtitle: _security.hasPinSet
                      ? 'Locks Habitat whenever the application closes'
                      : 'Requires a PIN to be configured first',
                  toggleValue: _security.appLockEnabled,
                  onToggleChanged: (val) {
                    if (val && !_security.hasPinSet) {
                      _showSetPinDialog();
                    } else {
                      _update(_security.copyWith(appLockEnabled: val));
                    }
                  },
                ),
                SettingsTile(
                  icon: Icons.pin_outlined,
                  title: 'Configure Security PIN',
                  subtitle: _security.hasPinSet ? 'PIN is active • Tap to change' : 'No PIN configured',
                  onTap: _showSetPinDialog,
                ),
                SettingsTile(
                  icon: Icons.fingerprint,
                  title: 'Biometric Unlock (Fingerprint / Face ID)',
                  subtitle: 'Use native hardware sensors when supported',
                  toggleValue: _security.biometricEnabled,
                  onToggleChanged: (val) => _update(_security.copyWith(biometricEnabled: val)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
