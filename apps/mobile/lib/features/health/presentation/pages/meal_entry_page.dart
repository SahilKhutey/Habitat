// Habitat Meal Entry Modal/Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../domain/models/meal_entry.dart';
import '../../domain/repositories/health_repository.dart';
import '../../domain/services/meal_service.dart';
import '../widgets/meal_selector.dart';

class MealEntryPage extends StatefulWidget {
  final MealType initialType;
  final MealEntryModel? existingEntry;

  const MealEntryPage({
    super.key,
    this.initialType = MealType.breakfast,
    this.existingEntry,
  });

  @override
  State<MealEntryPage> createState() => _MealEntryPageState();
}

class _MealEntryPageState extends State<MealEntryPage> {
  late MealType _selectedType;
  late TimeOfDay _selectedTime;
  late final TextEditingController _notesController;
  late final MealService _mealService;

  @override
  void initState() {
    super.initState();
    _mealService = MealService(HealthRepository(LocalDatabase.instance));
    _selectedType = widget.existingEntry?.type ?? widget.initialType;
    if (widget.existingEntry != null) {
      _selectedTime = TimeOfDay.fromDateTime(widget.existingEntry!.recordedAt);
      _notesController = TextEditingController(text: widget.existingEntry!.notes ?? '');
    } else {
      _selectedTime = TimeOfDay.now();
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final now = DateTime.now();
    final timestamp = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (widget.existingEntry != null) {
      _mealService.updateMeal(
        id: widget.existingEntry!.id,
        type: _selectedType,
        notes: _notesController.text.trim(),
      );
    } else {
      _mealService.logMeal(
        type: _selectedType,
        notes: _notesController.text.trim(),
        timestamp: timestamp,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ ${_selectedType.name.toUpperCase()} logged cleanly!'),
        backgroundColor: HabitatTheme.surfacePrimary,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingEntry != null;

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: Text(isEditing ? 'EDIT MEAL' : 'LOG MEAL'),
        backgroundColor: HabitatTheme.background,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Meal Type Selection
              const Text(
                'MEAL TYPE',
                style: TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: HabitatTheme.youngLeaf,
                ),
              ),
              const SizedBox(height: 10),
              MealSelector(
                selectedType: _selectedType,
                onTypeSelected: (type) => setState(() => _selectedType = type),
              ),
              const SizedBox(height: 24),

              // 2. Time Selector
              const Text(
                'TIME RECORDED',
                style: TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: HabitatTheme.youngLeaf,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (picked != null) {
                    setState(() => _selectedTime = picked);
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HabitatTheme.surfacePrimary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: HabitatTheme.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: Color(0xFFF72585)),
                          const SizedBox(width: 12),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(
                              fontFamily: HabitatTheme.fontHeading,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Change',
                        style: TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 12,
                          color: Color(0xFFF72585),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Optional Notes
              const Text(
                'NOTES / FOOD DESCRIPTION (OPTIONAL)',
                style: TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: HabitatTheme.youngLeaf,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. Oats, berries, black coffee',
                  hintStyle: const TextStyle(color: HabitatTheme.textMuted),
                  filled: true,
                  fillColor: HabitatTheme.surfacePrimary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: HabitatTheme.surfaceBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: HabitatTheme.surfaceBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFF72585))),
                ),
              ),
              const Spacer(),

              // 4. Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check, size: 20),
                  label: Text(
                    isEditing ? 'UPDATE MEAL' : 'RECORD MEAL',
                    style: const TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF72585),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
