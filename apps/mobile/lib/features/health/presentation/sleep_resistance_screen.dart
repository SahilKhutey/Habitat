// Sleep Architecture & Resistance Correlation Dashboard (Health V2 Layer)
import 'package:flutter/material.dart';
import '../../../core/theme/habitat_theme.dart';

class SleepResistanceScreen extends StatefulWidget {
  const SleepResistanceScreen({super.key});

  @override
  State<SleepResistanceScreen> createState() => _SleepResistanceScreenState();
}

class _SleepResistanceScreenState extends State<SleepResistanceScreen> {
  bool _adaptiveAlarmEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('HEALTH & SLEEP RESISTANCE'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Recovery Readiness Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: HabitatTheme.emeraldVictory.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PHYSIOLOGICAL RECOVERY',
                          style: TextStyle(
                              color: HabitatTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                      Chip(
                        backgroundColor: Color(0xFF1E2822),
                        label: Text('OPTIMAL READINESS',
                            style: TextStyle(
                                color: HabitatTheme.emeraldVictory,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('88',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900)),
                      Text('/100',
                          style: TextStyle(
                              color: HabitatTheme.textSecondary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'High deep sleep (1h 45m) and low waking resting heart rate. Your nervous system is primed for high-output physical routines.',
                    style: TextStyle(
                        color: HabitatTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Sleep Architecture Breakdown
            const Text('OVERNIGHT SLEEP ARCHITECTURE (7h 45m)',
                style: TextStyle(
                    color: HabitatTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HabitatTheme.surfaceBorder),
              ),
              child: Column(
                children: [
                  // Sleep bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 25,
                            child: Container(
                                height: 16,
                                color: const Color(0xFF5856D6))), // Deep
                        Expanded(
                            flex: 30,
                            child: Container(
                                height: 16,
                                color: const Color(0xFF0A84FF))), // REM
                        Expanded(
                            flex: 45,
                            child: Container(
                                height: 16,
                                color: const Color(0xFF64D2FF))), // Core
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StageIndicator(
                          color: Color(0xFF5856D6), label: 'Deep (1h 45m)'),
                      _StageIndicator(
                          color: Color(0xFF0A84FF), label: 'REM (2h 10m)'),
                      _StageIndicator(
                          color: Color(0xFF64D2FF), label: 'Core (3h 50m)'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Resistance vs Sleep Correlation Insight
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: HabitatTheme.amberFocus.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.insights,
                      color: HabitatTheme.amberFocus, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CORRELATION INSIGHT',
                            style: TextStyle(
                                color: HabitatTheme.amberFocus,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 1.2)),
                        SizedBox(height: 4),
                        Text(
                          'Over the last 14 days, nights with 7.5h+ sleep reduced your wake-up resistance by 42% (from 3.1m down to 1.8m).',
                          style: TextStyle(
                              color: Colors.white, fontSize: 13, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Adaptive Alarm Protocol Setting
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: HabitatTheme.surfaceBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Adaptive Alarm Protocol',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        SizedBox(height: 4),
                        Text(
                          'Automatically selects Hardcore vs Gentle mode based on overnight recovery score.',
                          style: TextStyle(
                              color: HabitatTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _adaptiveAlarmEnabled,
                    activeColor: HabitatTheme.amberFocus,
                    onChanged: (val) =>
                        setState(() => _adaptiveAlarmEnabled = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageIndicator extends StatelessWidget {
  final Color color;
  final String label;

  const _StageIndicator({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: HabitatTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
