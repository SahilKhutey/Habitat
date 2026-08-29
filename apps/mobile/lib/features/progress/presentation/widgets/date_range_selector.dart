// Habitat Date Range Selector Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';

class DateRangeSelector extends StatelessWidget {
  final String selectedTimeframe;
  final ValueChanged<String> onTimeframeChanged;

  const DateRangeSelector({
    super.key,
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = ['TODAY', 'WEEK', 'MONTH'];

    return Row(
      children: options.map((opt) {
        final isSelected = selectedTimeframe == opt;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Container(
                alignment: Alignment.center,
                child: Text(
                  opt,
                  style: TextStyle(
                    fontFamily: HabitatTheme.fontHeading,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? HabitatTheme.forest : Colors.white,
                  ),
                ),
              ),
              selected: isSelected,
              selectedColor: HabitatTheme.growthGreen,
              backgroundColor: HabitatTheme.surfacePrimary,
              onSelected: (_) => onTimeframeChanged(opt),
            ),
          ),
        );
      }).toList(),
    );
  }
}
