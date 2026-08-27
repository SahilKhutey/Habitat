// Multi-Stage Routine Stacks Screen & AI Rep-Counter HUD
import 'package:flutter/material.dart';
import '../../../core/theme/habitat_theme.dart';

class RoutineStackScreen extends StatefulWidget {
  const RoutineStackScreen({super.key});

  @override
  State<RoutineStackScreen> createState() => _RoutineStackScreenState();
}

class _RoutineStackScreenState extends State<RoutineStackScreen> {
  int _currentStepIndex = 0;
  int _repsCounted = 0;
  final int _targetReps = 10;
  bool _isRunningRoutine = false;

  final List<Map<String, dynamic>> _routineSteps = [
    {
      'step': 1,
      'title': 'Make Your Bed',
      'category': 'Morning Order',
      'proofType': 'PHOTO',
      'icon': Icons.bed,
      'xp': 50,
    },
    {
      'step': 2,
      'title': 'Drink 500ml Water',
      'category': 'Hydration',
      'proofType': 'PHOTO',
      'icon': Icons.water_drop,
      'xp': 40,
    },
    {
      'step': 3,
      'title': '10 Morning Push-Ups',
      'category': 'Physical Activation',
      'proofType': 'VIDEO',
      'icon': Icons.fitness_center,
      'xp': 80,
    },
  ];

  void _advanceStep() {
    if (_currentStepIndex < _routineSteps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _repsCounted = 0;
      });
    } else {
      setState(() {
        _isRunningRoutine = false;
      });
      _showVictoryDialog();
    }
  }

  void _showVictoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HabitatTheme.surfacePrimary,
        title: const Text('🏆 MORNING TRINITY COMPLETE!', style: TextStyle(color: HabitatTheme.amberFocus, fontWeight: FontWeight.bold)),
        content: const Text('You executed all 3 stages without cognitive friction.\n\n+170 Total XP Deposited in Ledger\nStreak Maintained 🔥'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ENTER DAY WITH DISCIPLINE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isRunningRoutine) {
      return _buildActiveRoutineView();
    }

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('DISCIPLINE ROUTINE STACKS'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Routine Header Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: HabitatTheme.amberFocus.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🌅 THE MORNING TRINITY', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                      Chip(
                        backgroundColor: Color(0xFF1E1E26),
                        label: Text('3 STEPS • +170 XP', style: TextStyle(color: HabitatTheme.amberFocus, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Eliminate morning decision fatigue: Smooth your bed, hydrate immediately, and activate neuromuscular energy in one unbroken sequence.',
                    style: TextStyle(color: HabitatTheme.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow, color: Colors.black),
                      label: const Text('START ROUTINE STACK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HabitatTheme.amberFocus,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        setState(() {
                          _isRunningRoutine = true;
                          _currentStepIndex = 0;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text('ROUTINE STACK SEQUENCE', style: TextStyle(color: HabitatTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),

            ..._routineSteps.asMap().entries.map((entry) {
              final step = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HabitatTheme.surfacePrimary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HabitatTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: HabitatTheme.amberFocus.withOpacity(0.15),
                      child: Text('${step['step']}', style: const TextStyle(color: HabitatTheme.amberFocus, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 14),
                    Icon(step['icon'] as IconData, color: HabitatTheme.amberFocus, size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          Text(step['category'] as String, style: const TextStyle(color: HabitatTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('+${step['xp']} XP', style: const TextStyle(color: HabitatTheme.amberFocus, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRoutineView() {
    final currentStep = _routineSteps[_currentStepIndex];
    final isVideo = currentStep['proofType'] == 'VIDEO';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Step Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _isRunningRoutine = false),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('STEP ${_currentStepIndex + 1} OF ${_routineSteps.length}', style: const TextStyle(color: HabitatTheme.amberFocus, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 2),
                        Text(currentStep['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Live Camera Viewfinder Overlay with AI HUD
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF141419),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: HabitatTheme.amberFocus, width: 2),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        isVideo ? Icons.accessibility_new : currentStep['icon'] as IconData,
                        size: 100,
                        color: Colors.white24,
                      ),
                    ),

                    // AI Pose Rep Counter HUD
                    if (isVideo)
                      Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: HabitatTheme.emeraldVictory),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.remove_red_eye, color: HabitatTheme.emeraldVictory, size: 18),
                                  SizedBox(width: 8),
                                  Text('AI POSE ENGINE ACTIVE', style: TextStyle(color: HabitatTheme.emeraldVictory, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                              Text('$_repsCounted / $_targetReps REPS', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Shutter / Simulate AI Rep Increment
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  if (isVideo && _repsCounted < _targetReps)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, color: Colors.black),
                      label: const Text('SIMULATE REP DETECTED', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: HabitatTheme.amberFocus),
                      onPressed: () {
                        setState(() {
                          _repsCounted++;
                        });
                      },
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isVideo && _repsCounted < _targetReps) ? Colors.grey : HabitatTheme.emeraldVictory,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: (isVideo && _repsCounted < _targetReps) ? null : _advanceStep,
                      child: Text(
                        _currentStepIndex < _routineSteps.length - 1 ? 'NEXT STAGE (STEP ${_currentStepIndex + 2})' : 'FINISH ROUTINE STACK',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
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
