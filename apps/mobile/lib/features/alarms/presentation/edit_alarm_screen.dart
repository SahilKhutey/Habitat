// Edit / Create Alarm Screen with Time Picker, 7-Day Selector & Discipline Modes
import 'package:flutter/material.dart';
import '../../../core/theme/habitat_theme.dart';

class EditAlarmScreen extends StatefulWidget {
  final Map<String, dynamic>? initialAlarm;

  const EditAlarmScreen({super.key, this.initialAlarm});

  @override
  State<EditAlarmScreen> createState() => _EditAlarmScreenState();
}

class _EditAlarmScreenState extends State<EditAlarmScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  final List<int> _selectedDays = [1, 2, 3, 4, 5]; // Mon-Fri default
  String _selectedTaskTitle = 'Make Your Bed';
  String _disciplineMode = 'DISCIPLINE';

  final List<String> _availableTasks = [
    'Make Your Bed',
    '10 Morning Push-Ups',
    'Drink 500ml Water',
    'Brush Teeth (2 Minutes)',
    'Morning Sunlight View',
    'Clear Workspace',
    '2-Minute Outdoor Walk',
    'Read 2 Physical Pages',
    '30-Second Full Body Stretch',
    'Night Prep: Tomorrow Clothes'
  ];

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
        _selectedDays.sort();
      }
    });
  }

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Alarm commitment set for ${_selectedTime.format(context)} ($disciplineModeDescription)')),
    );
    Navigator.of(context).pop();
  }

  String get disciplineModeDescription {
    switch (_disciplineMode) {
      case 'GENTLE':
        return '10 min retry interval • 0.9x XP';
      case 'HARDCORE':
        return '3 min retry interval • Max volume • 1.3x XP';
      default:
        return '5 min retry interval • Standard 1.0x XP';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeString = _selectedTime.format(context);

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('SET MISSION ALARM'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Time Display & Picker
              GestureDetector(
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
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: HabitatTheme.surfacePrimary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: HabitatTheme.amberFocus.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      const Text('WAKE-UP TIME',
                          style: TextStyle(
                              color: HabitatTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Text(
                        timeString,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2),
                      ),
                      const SizedBox(height: 6),
                      const Text('Tap to adjust',
                          style: TextStyle(
                              color: HabitatTheme.amberFocus,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 2. 7-Day Recurrence Selector
              const Text('REPEAT SCHEDULE',
                  style: TextStyle(
                      color: HabitatTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDayCircle(1, 'M'),
                  _buildDayCircle(2, 'T'),
                  _buildDayCircle(3, 'W'),
                  _buildDayCircle(4, 'T'),
                  _buildDayCircle(5, 'F'),
                  _buildDayCircle(6, 'S'),
                  _buildDayCircle(7, 'S'),
                ],
              ),
              const SizedBox(height: 28),

              // 3. Linked Mission Task Dropdown
              const Text('ASSIGNED MISSION TASK',
                  style: TextStyle(
                      color: HabitatTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedTaskTitle,
                dropdownColor: HabitatTheme.surfacePrimary,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: HabitatTheme.surfacePrimary,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                items: _availableTasks
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, style: const TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: (val) => setState(
                    () => _selectedTaskTitle = val ?? _selectedTaskTitle),
              ),
              const SizedBox(height: 28),

              // 4. Discipline Mode Selector
              const Text('DISCIPLINE ESCALATION PROTOCOL',
                  style: TextStyle(
                      color: HabitatTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildModeChoice(
                      'GENTLE', 'Gentle', HabitatTheme.emeraldVictory),
                  const SizedBox(width: 8),
                  _buildModeChoice(
                      'DISCIPLINE', 'Discipline', HabitatTheme.amberFocus),
                  const SizedBox(width: 8),
                  _buildModeChoice(
                      'HARDCORE', 'Hardcore', HabitatTheme.crimsonAlert),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                disciplineModeDescription,
                style: const TextStyle(
                    color: HabitatTheme.textSecondary, fontSize: 12),
              ),

              const SizedBox(height: 36),

              // 5. Save Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HabitatTheme.amberFocus,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _handleSave,
                  child: const Text('LOCK IN MISSION ALARM',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCircle(int isoDay, String label) {
    final isSelected = _selectedDays.contains(isoDay);
    return GestureDetector(
      onTap: () => _toggleDay(isoDay),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isSelected
              ? HabitatTheme.amberFocus
              : HabitatTheme.surfacePrimary,
          shape: BoxShape.circle,
          border: Border.all(
              color: isSelected
                  ? HabitatTheme.amberFocus
                  : HabitatTheme.surfaceBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : HabitatTheme.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeChoice(String mode, String label, Color accentColor) {
    final isSelected = _disciplineMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _disciplineMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withOpacity(0.15)
                : HabitatTheme.surfacePrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected ? accentColor : HabitatTheme.surfaceBorder),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? accentColor : HabitatTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
