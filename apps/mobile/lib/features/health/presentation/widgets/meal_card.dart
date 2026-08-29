// Habitat Meals Card Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/meal_entry.dart';

class MealCard extends StatelessWidget {
  final MealSummaryModel meals;
  final ValueChanged<MealType> onLogMeal;
  final VoidCallback? onOpenDetails;

  const MealCard({
    super.key,
    required this.meals,
    required this.onLogMeal,
    this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF72585).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF72585).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.restaurant, color: Color(0xFFF72585), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'MEAL NOURISHMENT',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${meals.loggedCount} / ${meals.targetCount} Logged',
                    style: const TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF72585),
                    ),
                  ),
                  if (onOpenDetails != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 18, color: Color(0xFFF72585)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onOpenDetails,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Meal Slot Rows
          _buildMealRow(MealType.breakfast, 'Breakfast', meals.breakfastEntry),
          const Divider(height: 16, color: HabitatTheme.surfaceBorder),
          _buildMealRow(MealType.lunch, 'Lunch', meals.lunchEntry),
          const Divider(height: 16, color: HabitatTheme.surfaceBorder),
          _buildMealRow(MealType.snack, 'Snacks', meals.snackEntry),
          const Divider(height: 16, color: HabitatTheme.surfaceBorder),
          _buildMealRow(MealType.dinner, 'Dinner', meals.dinnerEntry),
        ],
      ),
    );
  }

  Widget _buildMealRow(MealType type, String title, MealEntryModel? entry) {
    final isLogged = entry != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              isLogged ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: isLogged ? const Color(0xFFF72585) : HabitatTheme.textMuted,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 13,
                fontWeight: isLogged ? FontWeight.w700 : FontWeight.w500,
                color: isLogged ? Colors.white : HabitatTheme.textSecondary,
              ),
            ),
            if (isLogged && entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '• ${entry.notes}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: HabitatTheme.fontBody,
                  fontSize: 11,
                  color: HabitatTheme.textMuted,
                ),
              ),
            ],
          ],
        ),
        if (!isLogged)
          TextButton(
            onPressed: () => onLogMeal(type),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 26),
              backgroundColor: HabitatTheme.surfaceSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              '+ Log',
              style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF72585),
              ),
            ),
          )
        else
          Text(
            _formatTime(entry.recordedAt),
            style: const TextStyle(
              fontFamily: HabitatTheme.fontBody,
              fontSize: 11,
              color: HabitatTheme.textSecondary,
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
