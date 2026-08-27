// Tactical Alarms Management Screen
import 'package:flutter/material.dart';
import '../../../../packages/design_system/lib/design_system.dart';

class AlarmsHomeScreen extends StatefulWidget {
  const AlarmsHomeScreen({super.key});

  @override
  State<AlarmsHomeScreen> createState() => _AlarmsHomeScreenState();
}

class _AlarmsHomeScreenState extends State<AlarmsHomeScreen> {
  final List<Map<String, dynamic>> _alarms = [
    {
      'id': 'alarm-1',
      'time': '07:00 AM',
      'repeat': 'Mon, Tue, Wed, Thu, Fri',
      'task': '10 Morning Push-Ups',
      'mode': 'DISCIPLINE',
      'isEnabled': true,
      'xp': '+30 XP',
    },
    {
      'id': 'alarm-2',
      'time': '06:30 AM',
      'repeat': 'Sat, Sun',
      'task': 'Morning Outside Photo',
      'mode': 'GENTLE',
      'isEnabled': false,
      'xp': '+20 XP',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('WAKE-UP PROTOCOLS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm_add),
            tooltip: 'Simulate Alarm Ringing',
            onPressed: () {
              Navigator.of(context).pushNamed('/alarms/ringing');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Next Alarm Countdown Banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadii.radiusLarge,
                border: Border.all(color: AppColors.amberFocus.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.amberFocus, size: 32),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NEXT PROTOCOL IN', style: AppTypography.labelSmall),
                        const SizedBox(height: AppSpacing.xxs),
                        const Text('7h 23m (Tomorrow 07:00 AM)', style: AppTypography.titleLarge),
                        Text('10 Morning Push-Ups • +30 XP', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            const Text('ACTIVE ALARM COMMITMENTS', style: AppTypography.labelMedium),
            const SizedBox(height: AppSpacing.md),

            // Alarms List
            ..._alarms.map((alarm) {
              final isEnabled = alarm['isEnabled'] as bool;
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alarm['time'] as String,
                            style: AppTypography.displayLarge.copyWith(
                              color: isEnabled
                                  ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                  : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${alarm['task']} (${alarm['repeat']})',
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          DisciplineModeBadge(mode: alarm['mode'] as String),
                        ],
                      ),
                      Switch(
                        value: isEnabled,
                        activeColor: AppColors.amberFocus,
                        onChanged: (val) {
                          setState(() {
                            alarm['isEnabled'] = val;
                          });
                          AppFeedback.showToast(
                            context,
                            message: val ? 'Alarm Armed & Scheduled' : 'Alarm Disarmed',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.amberFocus,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_alarm),
        label: const Text('SET ALARM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        onPressed: () {
          Navigator.of(context).pushNamed('/alarms/create');
        },
      ),
    );
  }
}
