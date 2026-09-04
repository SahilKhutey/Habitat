// Tactical Full-Screen Alarm Ringing HUD
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import '../../../../core/platform/alarm/platform_alarm_service.dart';
import '../../../../core/alarm/native_alarm_service.dart';

class AlarmRingingScreen extends StatefulWidget {
  /// The active mission/alarm ID — used to disarm and cancel escalations.
  final String missionId;

  /// Human-readable task title shown on the ringing HUD.
  final String taskTitle;

  /// The time the alarm was originally scheduled to fire.
  final DateTime triggerTime;

  /// Which escalation attempt this is (1 = first, 2 = T+5min, …).
  final int attemptIndex;

  const AlarmRingingScreen({
    super.key,
    required this.missionId,
    required this.taskTitle,
    required this.triggerTime,
    this.attemptIndex = 1,
  });

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  /// Volume ramp: attempt 1 → 70 dB, 2 → 85 dB, 3+ → 100 dB
  int get _volumeDb {
    return switch (widget.attemptIndex) {
      1 => 70,
      2 => 85,
      _ => 100,
    };
  }

  String get _formattedTime {
    final h = widget.triggerTime.hour;
    final m = widget.triggerTime.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:$m $period';
  }

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

  Future<void> _disarmAndBeginMission() async {
    // Stop siren audio immediately
    await NativeAlarmService.stopSiren();

    // Cancel all pending escalation notifications
    final platformService = PlatformAlarmService.instance;
    await platformService.cancel(widget.missionId);

    if (mounted) {
      AppFeedback.showToast(
        context,
        message: 'Mission Active! Proof camera launching…',
      );
      Navigator.of(context).pop();
    }
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
              // ── Top Alert Banner ──────────────────────────────────────────
              Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.crimsonAlert,
                        size: 28,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'WAKE-UP ESCALATION ACTIVE'
                          ' • ATT #${widget.attemptIndex}'
                          ' ($_volumeDb dB)',
                          style: const TextStyle(
                            color: AppColors.crimsonAlert,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.taskTitle.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),

              // ── Animated Pulsing War Siren Icon ───────────────────────────
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
                        border:
                            Border.all(color: AppColors.crimsonAlert, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.crimsonAlert.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.volume_up,
                        color: AppColors.crimsonAlert,
                        size: 64,
                      ),
                    ),
                  );
                },
              ),

              // ── Bottom Action + Escalation Warning ────────────────────────
              Column(
                children: [
                  Text(
                    'No Snooze Allowed in Discipline Mode.\n'
                    '5-minute inactivity escalates siren to ${_volumeDb < 100 ? _volumeDb + 15 : 100} dB.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton.primary(
                    label: 'BEGIN MISSION & DISARM ALARM',
                    icon: Icons.fitness_center,
                    onPressed: _disarmAndBeginMission,
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
