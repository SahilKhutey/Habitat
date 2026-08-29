// Habitat Quick Actions Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';

class QuickActionBar extends StatelessWidget {
  final VoidCallback onLogWater;
  final VoidCallback onLogMeal;
  final VoidCallback onToggleNap;
  final VoidCallback? onAddTask;
  final bool napRunning;

  const QuickActionBar({
    super.key,
    required this.onLogWater,
    required this.onLogMeal,
    required this.onToggleNap,
    this.onAddTask,
    required this.napRunning,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Quick Actions Bar for rapid habit logging.',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: HabitatTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HabitatTheme.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            const Row(
              children: [
                Icon(Icons.bolt, size: 16, color: HabitatTheme.youngLeaf),
                SizedBox(width: 8),
                Text(
                  'QUICK ACTIONS',
                  style: TextStyle(
                    fontFamily: HabitatTheme.fontHeading,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: HabitatTheme.youngLeaf,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Quick Actions Button Wrap / Grid
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                // 1. Water
                _buildQuickButton(
                  context: context,
                  label: '+ 250ml Water',
                  icon: Icons.water_drop_outlined,
                  onPressed: () {
                    onLogWater();
                    _showFeedback(context, '💧 250ml water recorded');
                  },
                ),

                // 2. Meal
                _buildQuickButton(
                  context: context,
                  label: '+ Meal Log',
                  icon: Icons.restaurant_outlined,
                  onPressed: () {
                    onLogMeal();
                    _showFeedback(context, '🍽 Meal recorded');
                  },
                ),

                // 3. Nap Toggle
                _buildQuickButton(
                  context: context,
                  label: napRunning ? 'Stop Nap' : 'Start Nap',
                  icon: napRunning
                      ? Icons.stop_circle_outlined
                      : Icons.bedtime_outlined,
                  isActive: napRunning,
                  onPressed: () {
                    onToggleNap();
                    _showFeedback(
                      context,
                      napRunning ? '😴 Nap session stopped' : '😴 Nap started',
                    );
                  },
                ),

                // 4. Add Task
                if (onAddTask != null)
                  _buildQuickButton(
                    context: context,
                    label: '+ Task',
                    icon: Icons.add,
                    onPressed: onAddTask!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? HabitatTheme.habitatGreen
                : HabitatTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? HabitatTheme.growthGreen
                  : HabitatTheme.surfaceBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? HabitatTheme.growthGreen
                    : HabitatTheme.youngLeaf,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : HabitatTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: HabitatTheme.fontBody,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: HabitatTheme.surfacePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: HabitatTheme.surfaceBorder),
        ),
      ),
    );
  }
}
