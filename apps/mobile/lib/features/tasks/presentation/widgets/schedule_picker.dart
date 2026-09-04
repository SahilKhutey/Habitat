// Habitat Schedule Picker Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/schedule_model.dart';

class SchedulePicker extends StatelessWidget {
  final ScheduleRecurrenceType selectedRecurrence;
  final String timeOfDay;
  final List<int> repeatDays;
  final ValueChanged<ScheduleRecurrenceType> onRecurrenceChanged;
  final ValueChanged<String> onTimeChanged;
  final ValueChanged<List<int>> onDaysChanged;

  const SchedulePicker({
    super.key,
    required this.selectedRecurrence,
    required this.timeOfDay,
    required this.repeatDays,
    required this.onRecurrenceChanged,
    required this.onTimeChanged,
    required this.onDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time Selector Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: HabitatTheme.surfacePrimary,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: HabitatTheme.surfaceBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXECUTION TIME',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: HabitatTheme.youngLeaf,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'When should this discipline occur?',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontBody,
                      fontSize: 12,
                      color: HabitatTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () async {
                  final parts = timeOfDay.split(':');
                  final initialHour = int.tryParse(parts[0]) ?? 7;
                  final initialMinute =
                      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        TimeOfDay(hour: initialHour, minute: initialMinute),
                  );

                  if (picked != null) {
                    final h = picked.hour.toString().padLeft(2, '0');
                    final m = picked.minute.toString().padLeft(2, '0');
                    onTimeChanged('$h:$m');
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: HabitatTheme.habitatGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    timeOfDay,
                    style: const TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Recurrence Type Selector
        const Text(
          'RECURRENCE PATTERN',
          style: TextStyle(
            fontFamily: HabitatTheme.fontHeading,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: HabitatTheme.youngLeaf,
          ),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildRecurrenceChip('Daily', ScheduleRecurrenceType.daily),
            _buildRecurrenceChip('Weekdays', ScheduleRecurrenceType.weekdays),
            _buildRecurrenceChip('Weekends', ScheduleRecurrenceType.weekends),
            _buildRecurrenceChip('One-Time', ScheduleRecurrenceType.oneTime),
          ],
        ),
      ],
    );
  }

  Widget _buildRecurrenceChip(String label, ScheduleRecurrenceType type) {
    final isSelected = selectedRecurrence == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: HabitatTheme.growthGreen,
      backgroundColor: HabitatTheme.surfacePrimary,
      labelStyle: TextStyle(
        fontFamily: HabitatTheme.fontHeading,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        color: isSelected ? HabitatTheme.forest : Colors.white,
      ),
      onSelected: (_) {
        onRecurrenceChanged(type);
        if (type == ScheduleRecurrenceType.weekdays) {
          onDaysChanged([1, 2, 3, 4, 5]);
        } else if (type == ScheduleRecurrenceType.weekends) {
          onDaysChanged([6, 7]);
        } else {
          onDaysChanged([1, 2, 3, 4, 5, 6, 7]);
        }
      },
    );
  }
}
