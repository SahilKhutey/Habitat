// Habitat Alarm Card Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/alarm_model.dart';

class AlarmCard extends StatelessWidget {
  final TaskAlarmModel alarm;
  final String taskTitle;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.taskTitle,
    required this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Alarm at ${alarm.timeOfDay} for $taskTitle. ${alarm.isEnabled ? "Armed" : "Disabled"}.',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: HabitatTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: alarm.isEnabled
                ? HabitatTheme.growthGreen.withOpacity(0.4)
                : HabitatTheme.surfaceBorder,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Alarm Time Headline
                      Text(
                        alarm.timeOfDay,
                        style: TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: alarm.isEnabled ? Colors.white : HabitatTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Associated Task & Repeat
                      Text(
                        taskTitle,
                        style: const TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: HabitatTheme.youngLeaf,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _repeatDaysText(alarm.repeatDays),
                        style: const TextStyle(
                          fontFamily: HabitatTheme.fontBody,
                          fontSize: 11,
                          color: HabitatTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Toggle Switch
                  Switch(
                    value: alarm.isEnabled,
                    activeColor: HabitatTheme.growthGreen,
                    activeTrackColor: HabitatTheme.habitatGreen,
                    inactiveThumbColor: HabitatTheme.textMuted,
                    inactiveTrackColor: HabitatTheme.surfaceSecondary,
                    onChanged: onToggle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _repeatDaysText(List<int> days) {
    if (days.length == 7) return 'Every day • 5-min retry';
    if (days.length == 5 && !days.contains(6) && !days.contains(7)) {
      return 'Weekdays • 5-min retry';
    }
    return '${days.length} days / week • 5-min retry';
  }
}
