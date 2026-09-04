// Habitat Dedicated Water Intake Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../application/water_controller.dart';
import '../../domain/repositories/health_repository.dart';
import '../../domain/services/water_service.dart';
import '../widgets/water_quick_add.dart';

class WaterPage extends StatefulWidget {
  final WaterController? controller;

  const WaterPage({super.key, this.controller});

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage> {
  late final WaterController _controller;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      final db = LocalDatabase.instance;
      _controller = WaterController(
        waterService: WaterService(HealthRepository(db)),
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

  void _showChangeGoalDialog() {
    final goalController =
        TextEditingController(text: '${_controller.summary.targetMilliliters}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HabitatTheme.surfacePrimary,
        title: const Text('DAILY HYDRATION GOAL',
            style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        content: TextField(
          controller: goalController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Target Milliliters (ml)',
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
              final newGoal = int.tryParse(goalController.text) ?? 2000;
              if (newGoal > 0) {
                _controller.setGoal(newGoal);
              }
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CC9F0),
              foregroundColor: Colors.black,
            ),
            child: const Text('Save Goal',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final water = _controller.summary;
        final percentage = (water.progressPercentage * 100).toInt();

        return Scaffold(
          backgroundColor: HabitatTheme.background,
          appBar: AppBar(
            title: const Text('WATER INTAKE'),
            backgroundColor: HabitatTheme.background,
            actions: [
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.white),
                tooltip: 'Configure Daily Goal',
                onPressed: _showChangeGoalDialog,
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular / Gauge Centerpiece
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: HabitatTheme.surfacePrimary,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: const Color(0xFF4CC9F0).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF4CC9F0).withOpacity(0.15),
                            border: Border.all(
                                color: const Color(0xFF4CC9F0), width: 3),
                          ),
                          child: const Icon(Icons.water_drop,
                              color: Color(0xFF4CC9F0), size: 48),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${water.consumedMilliliters} ml',
                          style: const TextStyle(
                            fontFamily: HabitatTheme.fontHeading,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$percentage% of ${water.targetMilliliters} ml target (${water.remainingMilliliters} ml remaining)',
                          style: const TextStyle(
                            fontFamily: HabitatTheme.fontBody,
                            fontSize: 13,
                            color: Color(0xFF4CC9F0),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: water.progressPercentage,
                            minHeight: 10,
                            backgroundColor: HabitatTheme.surfaceSecondary,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF4CC9F0)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick-Add Presets
                  const Text(
                    'RAPID LOGGING',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: HabitatTheme.youngLeaf,
                    ),
                  ),
                  const SizedBox(height: 10),
                  WaterQuickAdd(
                      onAddWater: (amount) => _controller.addPreset(amount)),
                  const SizedBox(height: 28),

                  // Today's Entries Log
                  const Text(
                    "TODAY'S LOGGED GLASSES",
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: HabitatTheme.youngLeaf,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (water.entries.isEmpty)
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
                        'No water logged yet today. Tap above to record hydration.',
                        style: TextStyle(
                            color: HabitatTheme.textSecondary, fontSize: 13),
                      ),
                    )
                  else
                    ...water.entries.reversed.map((entry) {
                      final timeStr =
                          '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
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
                                const Icon(Icons.local_drink_outlined,
                                    size: 18, color: Color(0xFF4CC9F0)),
                                const SizedBox(width: 12),
                                Text(
                                  '+${entry.milliliters} ml',
                                  style: const TextStyle(
                                    fontFamily: HabitatTheme.fontHeading,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(timeStr,
                                    style: const TextStyle(
                                        color: HabitatTheme.textSecondary,
                                        fontSize: 12)),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      size: 16, color: HabitatTheme.textMuted),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () =>
                                      _controller.removeEntry(entry.id),
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
        );
      },
    );
  }
}
