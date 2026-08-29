// Habitat Unified Platform Permissions Diagnostic Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/services/permission_service.dart';
import '../widgets/permission_tile.dart';

class PermissionsPage extends StatelessWidget {
  const PermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService();
    final permissions = permissionService.getPermissionsDiagnostic();

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('PLATFORM PERMISSIONS'),
        backgroundColor: HabitatTheme.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Explanatory Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: HabitatTheme.growthGreen.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.health_and_safety_outlined, color: HabitatTheme.growthGreen, size: 24),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Habitat runs with minimal hardware permissions. Exact alarms and camera are required for un-cheatable discipline execution.',
                      style: TextStyle(
                        fontFamily: HabitatTheme.fontBody,
                        fontSize: 12,
                        color: HabitatTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'HARDWARE & PLATFORM ACCESS',
              style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: HabitatTheme.youngLeaf,
              ),
            ),
            const SizedBox(height: 12),

            ...permissions.map((item) {
              return PermissionTile(item: item);
            }),
          ],
        ),
      ),
    );
  }
}
