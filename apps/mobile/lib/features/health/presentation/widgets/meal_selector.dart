// Habitat Meal Type Selector Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/meal_entry.dart';

class MealSelector extends StatelessWidget {
  final MealType selectedType;
  final ValueChanged<MealType> onTypeSelected;

  const MealSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MealType.values.map((type) {
        final isSelected = selectedType == type;
        return ChoiceChip(
          label: Text(type.name.toUpperCase()),
          selected: isSelected,
          selectedColor: const Color(0xFFF72585),
          backgroundColor: HabitatTheme.surfaceSecondary,
          labelStyle: TextStyle(
            fontFamily: HabitatTheme.fontHeading,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : HabitatTheme.textSecondary,
          ),
          onSelected: (_) => onTypeSelected(type),
        );
      }).toList(),
    );
  }
}
