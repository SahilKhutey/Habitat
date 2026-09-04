// Alarm Reliability Onboarding & "Test My Alarm" Empirical Verification Screen (Milestone C2/C3)
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/alarm/battery_optimization_service.dart';
import '../../../services/alarm_reliability_service.dart';
import '../../../services/native_alarm_scheduler.dart';
import '../../alarms/domain/alarm_health_models.dart';
import '../widgets/reliability_check_tile.dart';
import '../widgets/reliability_step.dart';

class AlarmReliabilityScreen extends StatefulWidget {
  final VoidCallback? onCompleted;
  final bool isFromSettings;

  const AlarmReliabilityScreen({
    Key? key,
    this.onCompleted,
    this.isFromSettings = false,
  }) : super(key: key);

  @override
  State<AlarmReliabilityScreen> createState() => _AlarmReliabilityScreenState();
}

class _AlarmReliabilityScreenState extends State<AlarmReliabilityScreen>
    with WidgetsBindingObserver {
  final AlarmReliabilityService _reliabilityService =
      AlarmReliabilityService.instance;
  final IBatteryOptimizationService _batteryService =
      BatteryOptimizationService.instance;

  AlarmHealth? _health;
  bool _isLoading = true;
  bool _isTestingAlarm = false;
  int _testCountdown = 15;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runDiagnostic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Auto-recheck capabilities upon returning from system settings
      _runDiagnostic();
    }
  }

  Future<void> _runDiagnostic() async {
    setState(() => _isLoading = true);
    final health = await _reliabilityService.diagnoseAsync();
    if (mounted) {
      setState(() {
        _health = health;
        _isLoading = false;
      });
    }
  }

  void _startTestAlarm() async {
    setState(() {
      _isTestingAlarm = true;
      _testCountdown = 15;
    });

    final targetEpochMs = DateTime.now().millisecondsSinceEpoch + 15000;

    NativeAlarmScheduler.instance.scheduleExactAlarm(
      alarmId: 'test_alarm_${DateTime.now().millisecondsSinceEpoch}',
      missionId: 'reliability_test',
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(targetEpochMs),
    );

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_testCountdown > 1) {
        if (mounted) setState(() => _testCountdown--);
      } else {
        timer.cancel();
        if (mounted) _showTestResultDialog();
      }
    });
  }

  void _showTestResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16181D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '🔔 Did Your Test Alarm Fire?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'If your device turned on, showed the high-priority alarm notification, and played sound, your hardware path is empirically verified.',
          style: TextStyle(color: Color(0xFF9CA3AF), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isTestingAlarm = false);
            },
            child: const Text('No / Delayed',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
          ElevatedButton(
            onPressed: () {
              _reliabilityService.recordTestVerificationSuccess();
              Navigator.pop(ctx);
              setState(() => _isTestingAlarm = false);
              _runDiagnostic();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Real-device alarm execution verified!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Fired Loudly!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final health = _health;
    final warning = health != null
        ? _reliabilityService.getDegradationWarning(health)
        : null;
    final isVerified =
        _reliabilityService.persistedState?.isVerifiedViaTest ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0E11),
        elevation: 0,
        title: const Text(
          'Alarm Reliability',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _runDiagnostic,
            tooltip: 'Re-check capabilities',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Header Card
                  _buildStatusHeaderCard(health!, isVerified),
                  const SizedBox(height: 20),

                  // Warning degradation banner if any
                  if (warning != null && !isVerified) ...[
                    _buildWarningBanner(warning),
                    const SizedBox(height: 20),
                  ],

                  const Text(
                    'RELIABILITY CHECKLIST',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 1. Notifications Tile
                  ReliabilityCheckTile(
                    title: 'System Notifications',
                    description:
                        'Required to show high-priority wake-up alerts on lock screen.',
                    icon: Icons.notifications_active_outlined,
                    status: health.notificationsEnabled,
                    onFix: () => _batteryService.openBatterySettings(),
                  ),

                  // 2. Exact Alarms Tile
                  if (Platform.isAndroid)
                    ReliabilityCheckTile(
                      title: 'Exact Alarm Capability',
                      description:
                          'Allows millisecond-accurate RTC wakeup piercing deep Doze mode.',
                      icon: Icons.alarm_on_outlined,
                      status: health.canScheduleExactAlarms,
                      onFix: () => _batteryService.openExactAlarmSettings(),
                    ),

                  // 3. Battery Optimization Tile
                  if (Platform.isAndroid)
                    ReliabilityCheckTile(
                      title: 'Battery Optimization Exemption',
                      description:
                          'Prevents Android from killing background alarm receivers.',
                      icon: Icons.battery_charging_full_outlined,
                      status: health.batteryOptimizationStatus,
                      onFix: () => _batteryService.openBatterySettings(),
                    ),

                  const SizedBox(height: 20),

                  // OEM Guidance Section
                  if (health.oemGuidance != null &&
                      health.oemGuidance!.specificSteps.isNotEmpty)
                    _buildOemGuidanceCard(health.oemGuidance!),

                  const SizedBox(height: 28),

                  // "Test My Alarm" Section
                  _buildTestAlarmSection(),

                  const SizedBox(height: 32),

                  // Bottom Action Buttons
                  _buildBottomActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusHeaderCard(AlarmHealth health, bool isVerified) {
    final isReady =
        health.overallReliability == ReliabilityTier.excellent || isVerified;
    final isCritical = health.overallReliability == ReliabilityTier.critical;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified
              ? const Color(0xFF10B981)
              : (isReady
                  ? const Color(0xFF3B82F6)
                  : (isCritical
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF59E0B))),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVerified
                    ? Icons.verified
                    : (isReady
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded),
                color: isVerified
                    ? const Color(0xFF10B981)
                    : (isReady
                        ? const Color(0xFF3B82F6)
                        : (isCritical
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFF59E0B))),
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVerified
                        ? 'VERIFIED HARDWARE PATH'
                        : (isReady ? 'SYSTEM READY' : 'DEGRADED RELIABILITY'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isVerified
                          ? const Color(0xFF10B981)
                          : (isReady
                              ? const Color(0xFF3B82F6)
                              : (isCritical
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFF59E0B))),
                    ),
                  ),
                  Text(
                    'Device: ${health.manufacturer} (${health.platform.toUpperCase()})',
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isVerified
                ? 'Your device has been empirically tested and confirmed capable of piercing lock screen and power management constraints.'
                : (isReady
                    ? 'All standard native permissions are granted. Run a 15-second test alarm to verify real hardware wakeup.'
                    : 'Some system settings are restricting background alarm execution. Alarms may be delayed or silenced.'),
            style: const TextStyle(
                fontSize: 13, color: Color(0xFFD1D5DB), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(String warningText) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              warningText,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFFFCA5A5), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOemGuidanceCard(OEMGuidance guidance) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2E39)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_suggest_outlined,
                  color: Color(0xFF60A5FA), size: 20),
              const SizedBox(width: 8),
              Text(
                '${guidance.oemName.name.toUpperCase()} SPECIFIC INSTRUCTIONS',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF60A5FA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < guidance.specificSteps.length; i++)
            ReliabilityStepItem(
                stepNumber: i + 1, text: guidance.specificSteps[i]),
        ],
      ),
    );
  }

  Widget _buildTestAlarmSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, color: Color(0xFFFBBF24), size: 24),
              SizedBox(width: 8),
              Text(
                'Test My Alarm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Schedules a 15-second test alarm. Lock your phone now and confirm that the siren pierces lock screen & DND.',
            style:
                TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isTestingAlarm ? null : _startTestAlarm,
              icon: _isTestingAlarm
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.timer_outlined),
              label: Text(
                _isTestingAlarm
                    ? 'Firing in $_testCountdown s... (Lock Phone Now!)'
                    : 'Start 15s Test Alarm',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (widget.onCompleted != null) {
                widget.onCompleted!();
              } else {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save & Continue',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            if (widget.onCompleted != null) {
              widget.onCompleted!();
            } else {
              Navigator.of(context).pop();
            }
          },
          child: const Text(
            'Continue Anyway (Alarms May Be Delayed)',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
        ),
      ],
    );
  }
}
