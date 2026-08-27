// Alarm Management List Screen
import 'package:flutter/material.dart';
import '../../../core/theme/habitat_theme.dart';
import 'edit_alarm_screen.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
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
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('ALARM COMMITMENTS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: HabitatTheme.amberFocus),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const EditAlarmScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _alarms.length,
        itemBuilder: (context, index) {
          final alarm = _alarms[index];
          return _buildAlarmCard(alarm, index);
        },
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
                alarm['time'] as String,
                style: TextStyle(
                  color: isEnabled ? Colors.white : HabitatTheme.textMuted,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              Switch(
                value: isEnabled,
                activeColor: HabitatTheme.amberFocus,
                onChanged: (val) {
                  setState(() {
                    alarm['isEnabled'] = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.shield, size: 14, color: isEnabled ? HabitatTheme.amberFocus : HabitatTheme.textMuted),
              const SizedBox(width: 6),
              Text(
                alarm['taskTitle'] as String,
                style: TextStyle(
                  color: isEnabled ? HabitatTheme.textPrimary : HabitatTheme.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                alarm['repeat'] as String,
                style: const TextStyle(color: HabitatTheme.textSecondary, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: modeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: modeColor.withOpacity(0.5)),
                ),
                child: Text(
                  alarm['mode'] as String,
                  style: TextStyle(color: modeColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
