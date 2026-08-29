// Habitat Security Status Card Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/security_settings.dart';

class SecurityStatus extends StatelessWidget {
  final SecuritySettingsModel security;

  const SecurityStatus({super.key, required this.security});

  @override
  Widget build(BuildContext context) {
    final isSecured = security.appLockEnabled;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSecured
              ? HabitatTheme.growthGreen.withOpacity(0.4)
              : HabitatTheme.surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSecured ? HabitatTheme.habitatGreen : HabitatTheme.surfaceSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSecured ? Icons.lock_outline : Icons.lock_open_outlined,
              color: isSecured ? HabitatTheme.growthGreen : HabitatTheme.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSecured ? 'APP LOCK ACTIVE' : 'STANDARD PROTECTION',
                  style: TextStyle(
                    fontFamily: HabitatTheme.fontHeading,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isSecured ? HabitatTheme.growthGreen : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isSecured
                      ? 'Authentication required on app launch.'
                      : 'Enable app lock to require PIN or biometrics.',
                  style: const TextStyle(
                    fontFamily: HabitatTheme.fontBody,
                    fontSize: 12,
                    color: HabitatTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
