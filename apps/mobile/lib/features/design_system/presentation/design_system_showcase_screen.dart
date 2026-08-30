// Interactive Design System & Component Showcase Screen
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class DesignSystemShowcaseScreen extends StatefulWidget {
  const DesignSystemShowcaseScreen({super.key});

  @override
  State<DesignSystemShowcaseScreen> createState() => _DesignSystemShowcaseScreenState();
}

class _DesignSystemShowcaseScreenState extends State<DesignSystemShowcaseScreen> {
  int _counterSeconds = 85;
  bool _isLoadingButton = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatColors.background,
      appBar: AppBar(
        title: const Text('DESIGN SYSTEM & UX FOUNDATION'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(HabitatSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Color Palette Tokens
            const Text('COLOR PALETTE (HIGH-CONTRAST TACTICAL)', style: HabitatTypography.label),
            const SizedBox(height: HabitatSpacing.m),
            Row(
              children: [
                _buildColorSwatch('OBSIDIAN', HabitatColors.background),
                _buildColorSwatch('GUNMETAL', HabitatColors.surfacePrimary),
                _buildColorSwatch('CRIMSON', HabitatColors.crimsonAlert),
                _buildColorSwatch('AMBER', HabitatColors.amberFocus),
                _buildColorSwatch('EMERALD', HabitatColors.emeraldVictory),
                _buildColorSwatch('CYAN', HabitatColors.cyanTelemetry),
              ],
            ),
            const SizedBox(height: HabitatSpacing.xxl),

            // 2. Typography Scale
            const Text('TYPOGRAPHY SCALE', style: HabitatTypography.label),
            const SizedBox(height: HabitatSpacing.m),
            const Text('Display Large (32pt)', style: HabitatTypography.displayLarge),
            const SizedBox(height: HabitatSpacing.xs),
            const Text('Headline (18pt)', style: HabitatTypography.headline),
            const SizedBox(height: HabitatSpacing.xs),
            const Text('Title (15pt)', style: HabitatTypography.title),
            const SizedBox(height: HabitatSpacing.xs),
            const Text('Body Text (13pt) - Tactical legibility for groggy morning states.', style: HabitatTypography.body),
            const SizedBox(height: HabitatSpacing.xs),
            const Text('MONOSPACE COUNTER 01:25', style: HabitatTypography.monospaceCounter),
            const SizedBox(height: HabitatSpacing.xxl),

            // 3. Mission Status Badges
            const Text('MISSION STATUS BADGES', style: HabitatTypography.label),
            const SizedBox(height: HabitatSpacing.m),
            const Wrap(
              spacing: HabitatSpacing.xs,
              runSpacing: HabitatSpacing.xs,
              children: [
                MissionStatusBadge(status: 'SCHEDULED'),
                MissionStatusBadge(status: 'ACTIVE'),
                MissionStatusBadge(status: 'VERIFYING'),
                MissionStatusBadge(status: 'COMPLETED'),
                MissionStatusBadge(status: 'RETRYING'),
              ],
            ),
            const SizedBox(height: HabitatSpacing.xxl),

            // 4. Resistance Counter (ΔtR)
            const Text('RESISTANCE COUNTER COMPONENT (ΔtR)', style: HabitatTypography.label),
            const SizedBox(height: HabitatSpacing.m),
            Row(
              children: [
                Expanded(
                  child: ResistanceCounterWidget(elapsedSeconds: _counterSeconds),
                ),
                const SizedBox(width: HabitatSpacing.m),
                ElevatedButton(
                  onPressed: () => setState(() => _counterSeconds += 30),
                  child: const Text('+30s'),
                ),
              ],
            ),
            const SizedBox(height: HabitatSpacing.xxl),

            // 5. Button Variants
            const Text('DISCIPLINE BUTTON VARIANTS', style: HabitatTypography.label),
            const SizedBox(height: HabitatSpacing.m),
            DisciplineButton(
              label: 'PRIMARY AMBER ACTION',
              icon: Icons.bolt,
              isLoading: _isLoadingButton,
              onPressed: () {
                setState(() => _isLoadingButton = true);
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) setState(() => _isLoadingButton = false);
                });
              },
            ),
            const SizedBox(height: HabitatSpacing.s),
            DisciplineButton(
              label: 'CRIMSON ALERT (SIREN STOP)',
              icon: Icons.alarm_off,
              variant: DisciplineButtonVariant.alert,
              onPressed: () {},
            ),
            const SizedBox(height: HabitatSpacing.s),
            DisciplineButton(
              label: 'EMERALD VICTORY (PROCEED)',
              icon: Icons.check,
              variant: DisciplineButtonVariant.victory,
              onPressed: () {},
            ),
            const SizedBox(height: HabitatSpacing.s),
            DisciplineButton(
              label: 'OUTLINED SECONDARY',
              variant: DisciplineButtonVariant.outline,
              onPressed: () {},
            ),
            const SizedBox(height: HabitatSpacing.xxl),

            // 6. Tactical Shutter Button
            const Text('CAMERA SHUTTER COMPONENT', style: HabitatTypography.label),
            const SizedBox(height: HabitatSpacing.m),
            Center(
              child: TacticalShutterButton(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shutter triggered!')),
                  );
                },
              ),
            ),
            const SizedBox(height: HabitatSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatch(String name, Color color) {
    return Expanded(
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: HabitatRadii.radiusM,
          border: Border.all(color: Colors.white24),
        ),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          name,
          style: TextStyle(
            color: color == HabitatColors.background ? Colors.white : Colors.black,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
