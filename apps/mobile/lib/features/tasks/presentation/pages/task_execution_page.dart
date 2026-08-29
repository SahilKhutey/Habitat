// Habitat Task Execution HUD Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../application/execution_controller.dart';
import '../../domain/models/execution_model.dart';
import '../../domain/services/execution_service.dart';

class TaskExecutionPage extends StatefulWidget {
  final String taskId;
  final String? taskTitle;
  final String? proofType;

  const TaskExecutionPage({
    super.key,
    required this.taskId,
    this.taskTitle,
    this.proofType,
  });

  @override
  State<TaskExecutionPage> createState() => _TaskExecutionPageState();
}

class _TaskExecutionPageState extends State<TaskExecutionPage> with SingleTickerProviderStateMixin {
  late final ExecutionController _controller;
  late final AnimationController _radarAnim;

  @override
  void initState() {
    super.initState();
    _controller = ExecutionController(
      executionService: TaskExecutionService(database: LocalDatabase.instance),
      taskId: widget.taskId,
      taskTitle: widget.taskTitle,
    );
    _radarAnim = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _radarAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final execution = _controller.execution;

        if (_controller.isVerifying) {
          return _buildVerifyingView();
        }

        if (execution.status == ExecutionStatus.completed) {
          return _buildCelebrationView(execution);
        }

        if (execution.status == ExecutionStatus.retrying) {
          return _buildRetryView(execution);
        }

        return _buildActiveHUDView(execution);
      },
    );
  }

  Widget _buildActiveHUDView(TaskExecutionModel execution) {
    final proofType = widget.proofType ?? execution.proofType;

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('DISCIPLINE HUD'),
        backgroundColor: HabitatTheme.background,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Speed Bonus
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: HabitatTheme.habitatGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'IN PROGRESS',
                          style: TextStyle(
                            fontFamily: HabitatTheme.fontHeading,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: HabitatTheme.growthGreen,
                          ),
                        ),
                      ),
                      if (_controller.isSpeedBonusActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: HabitatTheme.growthGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: HabitatTheme.growthGreen),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.bolt, size: 12, color: HabitatTheme.growthGreen),
                              SizedBox(width: 4),
                              Text(
                                '+50% SPEED BONUS ACTIVE',
                                style: TextStyle(
                                  fontFamily: HabitatTheme.fontHeading,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: HabitatTheme.growthGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    execution.taskTitle,
                    style: const TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Proof Requirement: $proofType Evidence Validation',
                    style: const TextStyle(
                      fontFamily: HabitatTheme.fontBody,
                      fontSize: 12,
                      color: HabitatTheme.textSecondary,
                    ),
                  ),
                ],
              ),

              // Big Resistance Timer Display (ΔtR)
              Center(
                child: Column(
                  children: [
                    const Text(
                      'RESISTANCE TIME (ΔtR)',
                      style: TextStyle(
                        fontFamily: HabitatTheme.fontHeading,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: HabitatTheme.youngLeaf,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _controller.formattedTimer,
                      style: const TextStyle(
                        fontFamily: HabitatTheme.fontHeading,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                        color: HabitatTheme.growthGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _controller.isSpeedBonusActive
                          ? 'Finish under 02:00 for Instant Action Bonus'
                          : 'Standard Growth Points Active',
                      style: const TextStyle(
                        fontFamily: HabitatTheme.fontBody,
                        fontSize: 12,
                        color: HabitatTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Dominant Primary Action CTA
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => _controller.submitProof('local_proof_path_${DateTime.now().millisecondsSinceEpoch}.jpg'),
                  icon: Icon(proofType == 'VIDEO' ? Icons.videocam : Icons.camera_alt, size: 20),
                  label: Text(
                    'CAPTURE PROOF ($proofType)',
                    style: const TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HabitatTheme.growthGreen,
                    foregroundColor: HabitatTheme.forest,
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

  Widget _buildVerifyingView() {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _radarAnim,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: HabitatTheme.growthGreen.withOpacity(0.5), width: 2),
                ),
                child: const Icon(Icons.radar, color: HabitatTheme.growthGreen, size: 50),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'AUDITING PROOF TELEMETRY',
              style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Evaluating anti-cheat liveness & action verification...',
              style: TextStyle(
                fontFamily: HabitatTheme.fontBody,
                fontSize: 12,
                color: HabitatTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationView(TaskExecutionModel execution) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 20),

              Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: HabitatTheme.growthGreen.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: HabitatTheme.growthGreen, width: 3),
                    ),
                    child: const Icon(Icons.check, color: HabitatTheme.growthGreen, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'DISCIPLINE COMPLETE',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Wake-up siren disarmed. Proof evidence verified.',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontBody,
                      fontSize: 13,
                      color: HabitatTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Reward Details Box
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: HabitatTheme.surfacePrimary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: HabitatTheme.growthGreen.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '+${execution.xpAwarded} XP AWARDED',
                          style: const TextStyle(
                            fontFamily: HabitatTheme.fontHeading,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: HabitatTheme.growthGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          execution.isSpeedBonus ? 'Includes +50% Instant Action Bonus' : 'Standard Routine Bonus',
                          style: const TextStyle(
                            fontFamily: HabitatTheme.fontBody,
                            fontSize: 12,
                            color: HabitatTheme.youngLeaf,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Return Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.dashboard, size: 20),
                  label: const Text(
                    'RETURN TO HABITAT',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HabitatTheme.growthGreen,
                    foregroundColor: HabitatTheme.forest,
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

  Widget _buildRetryView(TaskExecutionModel execution) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 20),

              Column(
                children: [
                  const Icon(Icons.replay_circle_filled, color: Colors.orangeAccent, size: 72),
                  const SizedBox(height: 20),
                  const Text(
                    'VERIFICATION RETRY ARMED',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Verification was not accepted. 5-minute escalation retry has been armed with escalated alarm siren.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontBody,
                      fontSize: 13,
                      color: HabitatTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _controller.submitProof('retry_proof_${DateTime.now().millisecondsSinceEpoch}.jpg'),
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text(
                    'RETRY PROOF NOW',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HabitatTheme.growthGreen,
                    foregroundColor: HabitatTheme.forest,
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
