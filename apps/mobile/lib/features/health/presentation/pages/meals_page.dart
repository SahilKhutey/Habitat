// Habitat Dedicated Meals Management Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../application/meal_controller.dart';
import '../../domain/models/meal_entry.dart';
import '../../domain/repositories/health_repository.dart';
import '../../domain/services/meal_service.dart';
import '../widgets/meal_card.dart';
import 'meal_entry_page.dart';

class MealsPage extends StatefulWidget {
  final MealController? controller;

  const MealsPage({super.key, this.controller});

  @override
  State<MealsPage> createState() => _MealsPageState();
}

class _MealsPageState extends State<MealsPage> {
  late final MealController _controller;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      final db = LocalDatabase.instance;
      _controller = MealController(
        mealService: MealService(HealthRepository(db)),
        database: db,
      );
      _internalController = true;
    }
  }

  @override
  void dispose() {
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _openMealEntryModal([MealType? type, MealEntryModel? existing]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealEntryPage(
          initialType: type ?? MealType.breakfast,
          existingEntry: existing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final meals = _controller.summary;

        return Scaffold(
          backgroundColor: HabitatTheme.background,
          appBar: AppBar(
            title: const Text('MEAL NOURISHMENT'),
            backgroundColor: HabitatTheme.background,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 4-Slot Meal Card
                  MealCard(
                    meals: meals,
                    onLogMeal: (type) => _openMealEntryModal(type),
                  ),
                  const SizedBox(height: 28),

                  // Today's Detailed Meal Logs
                  const Text(
                    "TODAY'S RECORDED MEALS",
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: HabitatTheme.youngLeaf,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (meals.entries.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: HabitatTheme.surfacePrimary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: HabitatTheme.surfaceBorder),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'No meals recorded today. Tap below to log nourishment.',
                        style: TextStyle(color: HabitatTheme.textSecondary, fontSize: 13),
                      ),
                    )
                  else
                    ...meals.entries.map((entry) {
                      final timeStr = '${entry.recordedAt.hour.toString().padLeft(2, '0')}:${entry.recordedAt.minute.toString().padLeft(2, '0')}';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: HabitatTheme.surfacePrimary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: HabitatTheme.surfaceBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF72585).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.restaurant, color: Color(0xFFF72585), size: 18),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.typeDisplayName,
                                      style: const TextStyle(
                                        fontFamily: HabitatTheme.fontHeading,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (entry.notes != null && entry.notes!.isNotEmpty)
                                      Text(
                                        entry.notes!,
                                        style: const TextStyle(
                                          fontFamily: HabitatTheme.fontBody,
                                          fontSize: 12,
                                          color: HabitatTheme.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(timeStr, style: const TextStyle(color: HabitatTheme.textSecondary, fontSize: 12)),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: HabitatTheme.textMuted),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _controller.deleteMeal(entry.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFFF72585),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text(
              'LOG MEAL',
              style: TextStyle(fontFamily: HabitatTheme.fontHeading, fontWeight: FontWeight.w800),
            ),
            onPressed: () => _openMealEntryModal(),
          ),
        );
      },
    );
  }
}
