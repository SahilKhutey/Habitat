// Set Alarm Commitment Screen
import 'package:flutter/material.dart';
import '../../../../packages/design_system/lib/design_system.dart';

class CreateAlarmScreen extends StatefulWidget {
  const CreateAlarmScreen({super.key});

  @override
  State<CreateAlarmScreen> createState() => _CreateAlarmScreenState();
}

class _CreateAlarmScreenState extends State<CreateAlarmScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  final List<int> _selectedDays = [1, 2, 3, 4, 5]; // Mon - Fri
  String _disciplineMode = 'DISCIPLINE'; // GENTLE, DISCIPLINE, HARDCORE
  String _selectedTask = '10 Morning Push-Ups';

  final List<String> _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  void _saveAlarm() {
    AppFeedback.showToast(context, message: 'Alarm Committed for ${_selectedTime.format(context)}');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('COMMIT ALARM PROTOCOL'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Display Picker
            Center(
              child: InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (picked != null) {
                    setState(() => _selectedTime = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppRadii.radiusLarge,
                    border: Border.all(color: AppColors.amberFocus),
                  ),
                  child: Text(
                    _selectedTime.format(context),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Repeat Days
            const Text('REPEAT DAYS', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (idx) {
                final dayNum = idx + 1;
                final isSelected = _selectedDays.contains(dayNum);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDays.remove(dayNum);
                      } else {
                        _selectedDays.add(dayNum);
                      }
                    });
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.amberFocus : AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _days[idx],
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Discipline Escalation Mode
            const Text('DISCIPLINE ESCALATION LEVEL', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: ['GENTLE', 'DISCIPLINE', 'HARDCORE'].map((mode) {
                final isSelected = _disciplineMode == mode;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: AppButton.outline(
                      label: mode,
                      onPressed: () => setState(() => _disciplineMode = mode),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Bound Task Selection
            const Text('BOUND DISCIPLINE TASK', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.fitness_center, color: AppColors.amberFocus),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(_selectedTask, style: AppTypography.titleMedium)),
                  const Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            AppButton.primary(
              label: 'ARM & COMMIT WAKE-UP PROTOCOL',
              icon: Icons.shield,
              onPressed: _saveAlarm,
            ),
          ],
        ),
      ),
    );
  }
}
