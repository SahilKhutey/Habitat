// Alarm Management List Screen with Reliability Status & Navigation (Milestones C1-C3)
import 'package:flutter/material.dart';
import '../../../core/theme/habitat_theme.dart';
import '../../../services/alarm_reliability_service.dart';
import '../../onboarding/screens/alarm_reliability_screen.dart';
import 'edit_alarm_screen.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  final AlarmReliabilityService _reliabilityService =
      AlarmReliabilityService.instance;

  final List<Map<String, dynamic>> _alarms = [
    {
      'id': 'a1',
      'time': '07:00 AM',
      'taskTitle': 'Make Your Bed',
      'repeat': 'Mon, Tue, Wed, Thu, Fri',
      'mode': 'DISCIPLINE',
      'isEnabled': true,
      'baseXp': 50,
    },
    {
      'id': 'a2',
      'time': '08:30 AM',
      'taskTitle': '10 Morning Push-Ups',
      'repeat': 'Every day',
      'mode': 'HARDCORE',
      'isEnabled': true,
      'baseXp': 80,
    },
    {
      'id': 'a3',
      'time': '10:30 PM',
      'taskTitle': 'Night Prep: Tomorrow Clothes',
      'repeat': 'Mon, Tue, Wed, Thu, Sun',
      'mode': 'GENTLE',
      'isEnabled': false,
      'baseXp': 45,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isVerified =
        _reliabilityService.persistedState?.isVerifiedViaTest ?? false;

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('ALARM COMMITMENTS'),
        actions: [
          IconButton(
            icon: Icon(
              isVerified ? Icons.verified_user : Icons.security,
              color: isVerified
                  ? const Color(0xFF10B981)
                  : HabitatTheme.amberFocus,
            ),
            tooltip: 'Alarm Reliability & Diagnostics',
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const AlarmReliabilityScreen(isFromSettings: true),
                    ),
                  )
                  .then((_) => setState(() {}));
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: HabitatTheme.amberFocus),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const EditAlarmScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Reliability Status Banner
          _buildReliabilityBanner(isVerified),
          const SizedBox(height: 16),

          // Alarm Cards
          for (int i = 0; i < _alarms.length; i++)
            _buildAlarmCard(_alarms[i], i),
        ],
      ),
    );
  }

  Widget _buildReliabilityBanner(bool isVerified) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) =>
                    const AlarmReliabilityScreen(isFromSettings: true),
              ),
            )
            .then((_) => setState(() {}));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isVerified
              ? const Color(0xFF10B981).withOpacity(0.12)
              : const Color(0xFFF59E0B).withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isVerified
                ? const Color(0xFF10B981).withOpacity(0.3)
                : const Color(0xFFF59E0B).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isVerified ? Icons.verified : Icons.warning_amber_rounded,
              size: 20,
              color: isVerified
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isVerified
                    ? 'Hardware Alarm Path: Empirically Verified'
                    : 'Alarm Reliability: Check background & battery permissions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isVerified
                      ? const Color(0xFF10B981)
                      : const Color(0xFFFBBF24),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmCard(Map<String, dynamic> alarm, int index) {
    final isEnabled = alarm['isEnabled'] as bool;
    Color modeColor = HabitatTheme.amberFocus;
    if (alarm['mode'] == 'HARDCORE') modeColor = HabitatTheme.crimsonAlert;
    if (alarm['mode'] == 'GENTLE') modeColor = HabitatTheme.emeraldVictory;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEnabled ? HabitatTheme.surfaceBorder : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                alarm['time'],
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  color: isEnabled ? Colors.white : Colors.white38,
                ),
              ),
              Switch.adaptive(
                value: isEnabled,
                activeColor: HabitatTheme.amberFocus,
                onChanged: (val) {
                  setState(() {
                    _alarms[index]['isEnabled'] = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: modeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  alarm['mode'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: modeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alarm['taskTitle'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alarm['repeat'],
            style: const TextStyle(
              fontSize: 13,
              color: HabitatTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
