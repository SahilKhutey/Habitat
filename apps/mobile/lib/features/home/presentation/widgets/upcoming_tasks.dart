// Habitat Upcoming Tasks Preview Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/home_state_model.dart';

class UpcomingTasksCard extends StatelessWidget {
  final List<HomeTaskPreview> tasks;
  final VoidCallback? onOpenTasks;
  final ValueChanged<String>? onSelectTask;

  const UpcomingTasksCard({
    super.key,
    required this.tasks,
    this.onOpenTasks,
    this.onSelectTask,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Upcoming tasks: ${tasks.length} tasks scheduled.',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schedule,
                        size: 16, color: HabitatTheme.youngLeaf),
                    SizedBox(width: 8),
                    Text(
                      'UPCOMING',
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
                Text(
                  '${tasks.length} queued',
                  style: const TextStyle(
                    fontFamily: HabitatTheme.fontBody,
                    fontSize: 11,
                    color: HabitatTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tasks List or Empty State
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 20,
                        color: HabitatTheme.growthGreen.withOpacity(0.7)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'No upcoming tasks remaining.',
                        style: TextStyle(
                          fontFamily: HabitatTheme.fontBody,
                          fontSize: 13,
                          color: HabitatTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...tasks.map((task) => _buildTaskRow(task)),

            const SizedBox(height: 8),

            // Navigation Button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onOpenTasks,
                icon: const Icon(Icons.list_alt, size: 16),
                label: const Text('View All Disciplines'),
                style: TextButton.styleFrom(
                  foregroundColor: HabitatTheme.youngLeaf,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskRow(HomeTaskPreview task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: HabitatTheme.surfaceSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (onSelectTask != null) {
              onSelectTask!(task.id);
            } else if (onOpenTasks != null) {
              onOpenTasks!();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  task.taskType == 'VIDEO'
                      ? Icons.videocam_outlined
                      : Icons.camera_alt_outlined,
                  size: 18,
                  color: HabitatTheme.growthGreen,
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
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.detail,
                        style: const TextStyle(
                          fontFamily: HabitatTheme.fontBody,
                          fontSize: 11,
                          color: HabitatTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: HabitatTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
