// Habitat Current Action Hero Card
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/home_state_model.dart';

class CurrentActionCard extends StatelessWidget {
  final CurrentAction? action;
  final ValueChanged<CurrentAction> onStart;
  final VoidCallback? onOpenTasks;
  final VoidCallback? onCreateFirstTask;

  const CurrentActionCard({
    super.key,
    required this.action,
    required this.onStart,
    this.onOpenTasks,
    this.onCreateFirstTask,
  });

  @override
  Widget build(BuildContext context) {
    if (action == null) {
      return _buildEmptyCard(context);
    }

    final isActive = action!.status == CurrentActionStatus.active ||
        action!.status == CurrentActionStatus.retryRequired;
    final isCompleted = action!.status == CurrentActionStatus.completed;

    return Semantics(
      container: true,
      label:
          'Current Action: ${action!.title}. Status: ${action!.status.name}. ${action!.detail}',
      child: Container(
        decoration: BoxDecoration(
          color: HabitatTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive
                ? HabitatTheme.growthGreen
                : isCompleted
                    ? HabitatTheme.youngLeaf.withOpacity(0.4)
                    : HabitatTheme.surfaceBorder,
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: HabitatTheme.growthGreen.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Header & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _statusColor(action!.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'CURRENT ACTION',
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
                _buildStatusBadge(action!.status),
              ],
            ),
            const SizedBox(height: 14),

            // Action Title & Verification Meta
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? HabitatTheme.habitatGreen
                        : HabitatTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _actionIcon(action!.taskType),
                    color: isActive
                        ? HabitatTheme.growthGreen
                        : HabitatTheme.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action!.title,
                        style: const TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action!.detail,
                        style: const TextStyle(
                          fontFamily: HabitatTheme.fontBody,
                          fontSize: 12,
                          color: HabitatTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Dominant Primary Action Button
            if (action!.isActionable)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.styleFrom(
                  backgroundColor: HabitatTheme.growthGreen,
                  foregroundColor: HabitatTheme.forest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ).buildButton(
                  context: context,
                  onPressed: () => onStart(action!),
                  icon: _ctaIcon(action!.status),
                  label: action!.ctaLabel,
                ),
              )
            else if (isCompleted)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: HabitatTheme.habitatGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: HabitatTheme.growthGreen.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle,
                        color: HabitatTheme.growthGreen, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Completed for today',
                      style: TextStyle(
                        fontFamily: HabitatTheme.fontHeading,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: HabitatTheme.growthGreen,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onOpenTasks,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: HabitatTheme.surfaceBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('View Task Details'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: HabitatTheme.surfaceBorder),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.spa_outlined,
                  color: HabitatTheme.growthGreen, size: 16),
              SizedBox(width: 8),
              Text(
                'CURRENT ACTION',
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
          const SizedBox(height: 12),
          const Text(
            'Your day is clear.',
            style: TextStyle(
              fontFamily: HabitatTheme.fontHeading,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create your first task to establish your routine and start building momentum.',
            style: TextStyle(
              fontFamily: HabitatTheme.fontBody,
              fontSize: 13,
              color: HabitatTheme.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onCreateFirstTask ?? onOpenTasks,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Create First Task',
                style: TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: HabitatTheme.growthGreen,
                foregroundColor: HabitatTheme.forest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(CurrentActionStatus status) {
    final (label, color, bg) = switch (status) {
      CurrentActionStatus.active => (
          'IN PROGRESS',
          HabitatTheme.growthGreen,
          HabitatTheme.habitatGreen
        ),
      CurrentActionStatus.retryRequired => (
          'RETRY',
          Colors.orangeAccent,
          Colors.orange.withOpacity(0.2)
        ),
      CurrentActionStatus.completed => (
          'COMPLETED',
          HabitatTheme.youngLeaf,
          HabitatTheme.surfaceSecondary
        ),
      CurrentActionStatus.missed => (
          'MISSED',
          Colors.redAccent,
          Colors.red.withOpacity(0.2)
        ),
      CurrentActionStatus.upcoming => (
          'UPCOMING',
          HabitatTheme.textSecondary,
          HabitatTheme.surfaceSecondary
        ),
      CurrentActionStatus.ready => (
          'READY',
          HabitatTheme.growthGreen,
          HabitatTheme.habitatGreen
        ),
      CurrentActionStatus.noAction => (
          'CLEAR',
          HabitatTheme.textMuted,
          HabitatTheme.surfaceSecondary
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: HabitatTheme.fontHeading,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(CurrentActionStatus status) => switch (status) {
        CurrentActionStatus.active ||
        CurrentActionStatus.ready =>
          HabitatTheme.growthGreen,
        CurrentActionStatus.retryRequired => Colors.orangeAccent,
        CurrentActionStatus.completed => HabitatTheme.youngLeaf,
        CurrentActionStatus.missed => Colors.redAccent,
        _ => HabitatTheme.textMuted,
      };

  IconData _actionIcon(String taskType) => switch (taskType) {
        'VIDEO' => Icons.videocam_outlined,
        'AUDIO' => Icons.mic_none_outlined,
        'SUMMARY' => Icons.check_circle_outline,
        _ => Icons.camera_alt_outlined,
      };

  IconData _ctaIcon(CurrentActionStatus status) => switch (status) {
        CurrentActionStatus.active => Icons.arrow_forward,
        CurrentActionStatus.retryRequired => Icons.refresh,
        _ => Icons.play_arrow,
      };
}

extension on ButtonStyle {
  Widget buildButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return ElevatedButton.icon(
      style: this,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: HabitatTheme.fontHeading,
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
