// Tactical Full-Screen Alarm Ringing HUD
import 'package:flutter/material.dart';
import '../../../../packages/design_system/lib/design_system.dart';

class AlarmRingingScreen extends StatefulWidget {
  const AlarmRingingScreen({super.key});

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _attemptIndex = 1;
  int _volumeDb = 70;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Alert Banner
              Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.crimsonAlert, size: 28),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'WAKE-UP ESCALATION ACTIVE • ATT #$_attemptIndex ($_volumeDb dB)',
                        style: const TextStyle(
                          color: AppColors.crimsonAlert,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('07:00 AM', style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white)),
                  const Text('10 MORNING PUSH-UPS PROTOCOL', style: TextStyle(color: Colors.white70, letterSpacing: 1)),
                ],
              ),

              // Animated Pulsing War Siren Icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.15);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.crimsonAlert.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.crimsonAlert, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.crimsonAlert.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.volume_up, color: AppColors.crimsonAlert, size: 64),
                    ),
                  );
                },
              ),

              // Bottom Instant Action Button
              Column(
                children: [
                  Text(
                    'No Snooze Allowed in Discipline Mode.\n5-minute inactivity will escalate siren volume to 85 dB.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton.primary(
                    label: 'BEGIN MISSION & DISARM ALARM',
                    icon: Icons.fitness_center,
                    onPressed: () {
                      AppFeedback.showToast(context, message: 'Mission Active! Proof camera launching...');
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
