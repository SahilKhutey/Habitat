// Habitat Task Card Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/action_model.dart';
import '../../domain/models/task_model.dart';
import 'task_status.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback? onStart;
  final VoidCallback? onTogglePause;
  final VoidCallback? onArchive;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.onStart,
    this.onTogglePause,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final isReady =
        task.status == TaskStatus.ready || task.status == TaskStatus.active;
    final isCompleted = task.status == TaskStatus.completed;

    return Semantics(
      container: true,
      label:
          'Task: ${task.title}. Status: ${task.status.name}. Schedule: ${task.schedule.timeOfDay}.',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: HabitatTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isReady
                ? HabitatTheme.growthGreen.withOpacity(0.4)
                : isCompleted
                    ? HabitatTheme.youngLeaf.withOpacity(0.3)
                    : HabitatTheme.surfaceBorder,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Metadata Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          TaskStatusBadge(status: task.status),
                          const SizedBox(width: 8),
                          Text(
                            task.categoryDisplayName,
                            style: const TextStyle(
                              fontFamily: HabitatTheme.fontHeading,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: HabitatTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '+${task.baseXp} XP',
                            style: const TextStyle(
                              fontFamily: HabitatTheme.fontHeading,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: HabitatTheme.growthGreen,
                            ),
                          ),
                          if (onTogglePause != null || onArchive != null) ...[
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  size: 18, color: HabitatTheme.textMuted),
                              color: HabitatTheme.surfacePrimary,
                              onSelected: (val) {
                                if (val == 'pause' && onTogglePause != null) {
                                  onTogglePause!();
                                } else if (val == 'archive' &&
                                    onArchive != null) {
                                  onArchive!();
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'pause',
                                  child: Text(task.status == TaskStatus.paused
                                      ? 'Resume Task'
                                      : 'Pause Task'),
                                ),
                                const PopupMenuItem(
                                  value: 'archive',
                                  child: Text('Archive Task'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title & Action Icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isReady
                              ? HabitatTheme.habitatGreen
                              : HabitatTheme.surfaceSecondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          task.action.type == ActionType.video
                              ? Icons.videocam_outlined
                              : Icons.camera_alt_outlined,
                          size: 20,
                          color: isReady
                              ? HabitatTheme.growthGreen
                              : HabitatTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                fontFamily: HabitatTheme.fontHeading,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${task.schedule.timeOfDay} • ${task.schedule.recurrenceDisplayName}',
                              style: const TextStyle(
                                fontFamily: HabitatTheme.fontBody,
                                fontSize: 12,
                                color: HabitatTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Bottom Action CTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            task.alarm != null && task.alarm!.isEnabled
                                ? Icons.alarm_on
                                : Icons.alarm_off,
                            size: 14,
                            color: task.alarm != null && task.alarm!.isEnabled
                                ? HabitatTheme.youngLeaf
                                : HabitatTheme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            task.alarm != null && task.alarm!.isEnabled
                                ? 'Alarm Armed'
                                : 'No Alarm',
                            style: TextStyle(
                              fontFamily: HabitatTheme.fontBody,
                              fontSize: 11,
                              color: task.alarm != null && task.alarm!.isEnabled
                                  ? HabitatTheme.youngLeaf
                                  : HabitatTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      if (onStart != null && isReady)
                        ElevatedButton(
                          onPressed: onStart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HabitatTheme.growthGreen,
                            foregroundColor: HabitatTheme.forest,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'Start',
                            style: TextStyle(
                              fontFamily: HabitatTheme.fontHeading,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        const Icon(Icons.chevron_right,
                            size: 18, color: HabitatTheme.textMuted),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
