// Habitat Water Quick Add Presets Bar
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';

class WaterQuickAdd extends StatelessWidget {
  final ValueChanged<int> onAddWater;

  const WaterQuickAdd({super.key, required this.onAddWater});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildChip(context, '+250 ml', 250),
        const SizedBox(width: 8),
        _buildChip(context, '+500 ml', 500),
        const SizedBox(width: 8),
        _buildChip(context, '+750 ml', 750),
        const SizedBox(width: 8),
        _buildCustomButton(context),
      ],
    );
  }

  Widget _buildChip(BuildContext context, String label, int amount) {
    return Expanded(
      child: InkWell(
        onTap: () => onAddWater(amount),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: HabitatTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4CC9F0).withOpacity(0.3)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: HabitatTheme.fontHeading,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4CC9F0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomButton(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => _showCustomDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: HabitatTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HabitatTheme.surfaceBorder),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Custom',
            style: TextStyle(
              fontFamily: HabitatTheme.fontHeading,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomDialog(BuildContext context) {
    final controller = TextEditingController(text: '350');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HabitatTheme.surfacePrimary,
        title: const Text('CUSTOM WATER INTAKE',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Milliliters (ml)',
            labelStyle: const TextStyle(color: HabitatTheme.textSecondary),
            filled: true,
            fillColor: HabitatTheme.surfaceSecondary,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: HabitatTheme.surfaceBorder)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: HabitatTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                onAddWater(amount);
              }
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CC9F0),
              foregroundColor: Colors.black,
            ),
            child: const Text('Add Water',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
